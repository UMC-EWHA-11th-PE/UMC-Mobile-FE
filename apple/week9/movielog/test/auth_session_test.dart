import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/auth_view_model.dart';

import 'fake_auth.dart';
import 'fake_favorites.dart';
import 'fake_tmdb.dart';

void main() {
  group('restoreSession', () {
    test('토큰이 없으면 서버에 묻지 않고 signedOut', () async {
      final api = FakeMemberApiService();
      final auth = fakeAuth(token: null, memberApi: api);

      await auth.initialize();

      expect(auth.status, AuthStatus.signedOut);
      expect(api.calls, 0);
      expect(auth.member, isNull);
    });

    test('토큰이 있고 /members/me가 성공해야 signedIn', () async {
      final auth = fakeAuth();

      await auth.initialize();

      expect(auth.status, AuthStatus.signedIn);
      expect(auth.member?.nickname, '밍고');
      expect(auth.memberStatus, MemberLoadStatus.success);
    });

    for (final code in ['AUTH401_2', 'AUTH401_3', 'AUTH401_4']) {
      test('$code면 토큰을 지우고 만료(sessionExpired)로 signedOut', () async {
        final storage = InMemoryTokenStorage('expired-token');
        final auth = fakeAuth(
          storage: storage,
          memberApi: FakeMemberApiService(errorCode: code),
        );

        await auth.initialize();

        expect(auth.status, AuthStatus.signedOut);
        expect(storage.token, isNull);
        expect(auth.sessionExpired, isTrue);
      });
    }

    test('MEMBER404_1이면 재시도해도 같으므로 토큰을 지우고 signedOut', () async {
      final storage = InMemoryTokenStorage('token');
      final auth = fakeAuth(
        storage: storage,
        memberApi: FakeMemberApiService(
          errorCode: 'MEMBER404_1',
          errorStatus: 404,
        ),
      );

      await auth.initialize();

      expect(auth.status, AuthStatus.signedOut);
      expect(storage.token, isNull);
    });

    test('연결 실패는 토큰을 지우지 않고 retryRequired', () async {
      final storage = InMemoryTokenStorage('valid-token');
      final api = FakeMemberApiService(connectionError: true);
      final auth = fakeAuth(storage: storage, memberApi: api);

      await auth.initialize();

      expect(auth.status, AuthStatus.retryRequired);
      expect(storage.token, 'valid-token');
      expect(storage.deleteCount, 0);
      expect(auth.message, '로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.');

      // 다시 시도 → 연결이 돌아오면 같은 토큰으로 signedIn
      api.connectionError = false;
      await auth.initialize();
      expect(auth.status, AuthStatus.signedIn);
      expect(auth.message, isNull);
    });

    test('500 서버 오류도 토큰을 지우지 않고 retryRequired', () async {
      final storage = InMemoryTokenStorage('valid-token');
      final auth = fakeAuth(
        storage: storage,
        memberApi: FakeMemberApiService(
          errorCode: 'COMMON500',
          errorStatus: 500,
        ),
      );

      await auth.initialize();

      expect(auth.status, AuthStatus.retryRequired);
      expect(storage.token, 'valid-token');
    });

    test('저장소를 읽지 못하면 retryRequired와 저장소 안내 문구', () async {
      final storage = InMemoryTokenStorage('token')..failRead = true;
      final auth = fakeAuth(storage: storage);

      await auth.initialize();

      expect(auth.status, AuthStatus.retryRequired);
      expect(auth.message, '인증 저장소를 읽지 못했어요. 다시 시도해 주세요.');
    });

    test('재설치 정리가 실패하면 토큰을 읽지 않고, 다시 시도 때 정리부터 한다', () async {
      var cleanupCalls = 0;
      var failCleanup = true;
      final api = FakeMemberApiService();
      final auth = AuthViewModel(
        FakeAuthApiService(),
        api,
        InMemoryTokenStorage('token'),
        storageCleanup: () async {
          cleanupCalls++;
          if (failCleanup) throw Exception('keychain unavailable');
        },
      );

      await auth.initialize();
      expect(auth.status, AuthStatus.retryRequired);
      expect(api.calls, 0);

      failCleanup = false;
      await auth.initialize();
      expect(cleanupCalls, 2);
      expect(auth.status, AuthStatus.signedIn);

      // 정리는 한 번 성공하면 다시 하지 않습니다.
      await auth.initialize();
      expect(cleanupCalls, 2);
    });

    test('이전 확인 요청의 늦은 401은 새 세션을 지우지 않는다', () async {
      final storage = InMemoryTokenStorage('token');
      final gate = Completer<void>();
      final api = FakeMemberApiService(gate: gate.future);
      final auth = fakeAuth(storage: storage, memberApi: api);

      final first = auth.restoreSession(); // 응답 대기
      api.gate = null;
      await auth.restoreSession(); // 새 확인 → 성공
      expect(auth.status, AuthStatus.signedIn);

      // 첫 요청이 뒤늦게 401로 끝나도 무시
      api.errorCode = 'AUTH401_4';
      gate.complete();
      await first;

      expect(auth.status, AuthStatus.signedIn);
      expect(storage.token, 'token');
      expect(storage.deleteCount, 0);
    });
  });

  group('authRedirect', () {
    test('확인 중·확인 실패는 스플래시(/start)에 머문다', () {
      for (final status in [
        AuthStatus.initializing,
        AuthStatus.retryRequired,
      ]) {
        expect(authRedirect(status, '/start'), isNull);
        expect(authRedirect(status, '/home'), '/start');
        expect(authRedirect(status, '/login'), '/start');
      }
    });

    test('로그아웃·로그인 중에는 로그인·회원가입만 허용한다', () {
      for (final status in [AuthStatus.signedOut, AuthStatus.authenticating]) {
        expect(authRedirect(status, '/login'), isNull);
        expect(authRedirect(status, '/register'), isNull);
        expect(authRedirect(status, '/start'), '/login');
        expect(authRedirect(status, '/my/ratings'), '/login');
        expect(authRedirect(status, '/movies/550'), '/login');
      }
    });

    test('로그인되면 스플래시·로그인·회원가입은 홈으로, 보호 화면은 그대로', () {
      expect(authRedirect(AuthStatus.signedIn, '/start'), '/home');
      expect(authRedirect(AuthStatus.signedIn, '/login'), '/home');
      expect(authRedirect(AuthStatus.signedIn, '/register'), '/home');
      expect(authRedirect(AuthStatus.signedIn, '/my/ratings'), isNull);
      expect(authRedirect(AuthStatus.signedIn, '/movies/550'), isNull);
    });
  });

  testWidgets('스플래시: 확인 중 로딩 → 실패 시 다시 시도 → 성공하면 홈으로 이동', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final gate = Completer<void>();
    final api = FakeMemberApiService(connectionError: true, gate: gate.future);
    final auth = fakeAuth(memberApi: api);

    // 확인 전(initializing) 세션을 넘기면 앱이 첫 프레임 뒤 복원을 시작합니다.
    await tester.pumpWidget(
      MovieLogApp(
        authViewModel: auth,
        tmdbMovieService: fakeTmdbService(),
        favoriteApiService: FakeFavoriteServer().service,
      ),
    );
    await tester.pump();

    String location() =>
        appRouter(tester).routerDelegate.currentConfiguration.uri.path;

    // /members/me 응답 전: 스플래시 + 로딩
    expect(api.calls, 1);
    expect(location(), '/start');
    expect(find.text('FLUTTER 8주차'), findsOneWidget);
    expect(find.text('다시 시도'), findsNothing);

    // 연결 실패 → 같은 스플래시에서 다시 시도 버튼
    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(location(), '/start');
    expect(find.text('로그인 상태를 확인하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);

    // 연결이 돌아온 뒤 다시 시도 → 서버 검증 성공 → 홈
    api.connectionError = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(location(), '/home');
  });
}
