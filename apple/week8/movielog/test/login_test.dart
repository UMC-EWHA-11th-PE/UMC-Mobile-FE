import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';

import 'fake_auth.dart';
import 'fake_sign_up.dart';
import 'fake_tmdb.dart';

void main() {
  group('AuthViewModel.login', () {
    test('성공하면 토큰을 저장하고 signedIn — 내 정보는 아직 부르지 않는다', () async {
      final storage = InMemoryTokenStorage();
      final authApi = FakeAuthApiService(accessToken: 'jwt-1');
      final memberApi = FakeMemberApiService();
      final auth = fakeAuth(
        storage: storage,
        authApi: authApi,
        memberApi: memberApi,
      );
      await auth.initialize();
      expect(auth.status, AuthStatus.signedOut);

      await auth.login('  movie@example.com ', 'Umc1234!');

      expect(auth.status, AuthStatus.signedIn);
      expect(storage.token, 'jwt-1');
      expect(authApi.requests.single.toJson(), {
        'email': 'movie@example.com',
        'password': 'Umc1234!',
      });
      expect(auth.member, isNull);
      expect(memberApi.calls, 0);
    });

    test('AUTH401_1은 로그인 Form 오류 — 세션 정리 없이 입력칸 문구만 남긴다', () async {
      final storage = InMemoryTokenStorage();
      final auth = fakeAuth(
        storage: storage,
        authApi: FakeAuthApiService(errorCode: 'AUTH401_1'),
      );
      await auth.initialize();

      await auth.login('movie@example.com', 'wrong');

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.loginError, '이메일 또는 비밀번호를 확인해 주세요.');
      expect(auth.message, isNull);
      expect(auth.sessionExpired, isFalse);
      expect(storage.deleteCount, 0);
      expect(storage.token, isNull);
    });

    test('COMMON400은 서버 message를 입력칸 아래에 그대로 보여준다', () async {
      final auth = fakeAuth(
        token: null,
        authApi: FakeAuthApiService(errorCode: 'COMMON400', errorStatus: 400),
      );
      await auth.initialize();

      await auth.login('movie', 'pw');

      expect(auth.loginError, 'server message for COMMON400');
    });

    test('연결 실패는 입력 오류가 아니라 화면 안내 문구로 남긴다', () async {
      final auth = fakeAuth(
        token: null,
        authApi: FakeAuthApiService(connectionError: true),
      );
      await auth.initialize();

      await auth.login('movie@example.com', 'Umc1234!');

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.loginError, isNull);
      expect(auth.message, '로그인 요청에 실패했어요. 잠시 후 다시 시도해 주세요.');
    });

    test('토큰 저장에 실패하면 signedIn으로 바꾸지 않는다', () async {
      final storage = InMemoryTokenStorage()..failSave = true;
      final auth = fakeAuth(storage: storage);
      await auth.initialize();

      await auth.login('movie@example.com', 'Umc1234!');

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.message, '로그인 정보를 안전하게 저장하지 못했어요.');
    });

    test('요청 중에 다시 눌러도 한 번만 보낸다', () async {
      final gate = Completer<void>();
      final authApi = FakeAuthApiService(gate: gate.future);
      final auth = fakeAuth(token: null, authApi: authApi);
      await auth.initialize();

      final first = auth.login('movie@example.com', 'Umc1234!');
      expect(auth.status, AuthStatus.authenticating);
      await auth.login('movie@example.com', 'Umc1234!');
      gate.complete();
      await first;

      expect(authApi.requests, hasLength(1));
      expect(auth.status, AuthStatus.signedIn);
    });

    test('입력이 바뀌면 이전 로그인 실패 문구를 지운다', () async {
      final auth = fakeAuth(
        token: null,
        authApi: FakeAuthApiService(errorCode: 'AUTH401_1'),
      );
      await auth.initialize();
      await auth.login('movie@example.com', 'wrong');

      auth.clearLoginError();

      expect(auth.loginError, isNull);
    });
  });

  group('AuthViewModel.loadMember', () {
    Future<(AuthViewModel, FakeMemberApiService, InMemoryTokenStorage)>
    signedInByLogin(FakeMemberApiService memberApi) async {
      final storage = InMemoryTokenStorage();
      final auth = fakeAuth(storage: storage, memberApi: memberApi);
      await auth.initialize();
      await auth.login('movie@example.com', 'Umc1234!');
      return (auth, memberApi, storage);
    }

    test('로그인 뒤 한 번 불러와 보관하고, 이미 있으면 다시 부르지 않는다', () async {
      final (auth, memberApi, _) = await signedInByLogin(
        FakeMemberApiService(),
      );

      await auth.loadMember();
      await auth.loadMember();

      expect(auth.member?.nickname, '밍고');
      expect(auth.memberStatus, MemberLoadStatus.success);
      expect(memberApi.calls, 1);

      await auth.loadMember(force: true);
      expect(memberApi.calls, 2);
    });

    test('앱 재시작으로 복원한 세션은 member가 있어 다시 부르지 않는다', () async {
      final memberApi = FakeMemberApiService();
      final auth = fakeAuth(memberApi: memberApi);
      await auth.initialize();

      await auth.loadMember();

      expect(memberApi.calls, 1); // restoreSession의 GET me 한 번뿐
    });

    test('AUTH401_4면 토큰을 지우고 만료로 signedOut', () async {
      final (auth, memberApi, storage) = await signedInByLogin(
        FakeMemberApiService(errorCode: 'AUTH401_4'),
      );

      await auth.loadMember();

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isTrue);
      expect(storage.token, isNull);
      expect(memberApi.calls, 1);
    });

    test('네트워크 실패는 로그아웃하지 않고 error로 남긴다', () async {
      final (auth, _, storage) = await signedInByLogin(
        FakeMemberApiService(connectionError: true),
      );

      await auth.loadMember();

      expect(auth.status, AuthStatus.signedIn);
      expect(auth.memberStatus, MemberLoadStatus.error);
      expect(auth.message, '내 정보를 불러오지 못했어요.');
      expect(storage.token, 'new-token');
    });
  });

  group('로그인 화면', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    Future<AuthViewModel> pumpLogin(
      WidgetTester tester, {
      FakeAuthApiService? authApi,
      FakeMemberApiService? memberApi,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final auth = fakeAuth(
        token: null,
        authApi: authApi,
        memberApi: memberApi,
      );
      await auth.initialize();
      await tester.pumpWidget(
        MovieLogApp(
          authViewModel: auth,
          tmdbMovieService: fakeTmdbService(),
          signUpService: fakeSignUpService(),
        ),
      );
      await tester.pumpAndSettle();
      return auth;
    }

    String location(WidgetTester tester) =>
        appRouter(tester).routerDelegate.currentConfiguration.uri.path;

    Finder emailField() => find.byType(TextField).at(0);
    Finder passwordField() => find.byType(TextField).at(1);
    MovieLogButton loginButton(WidgetTester tester) =>
        tester.widget<MovieLogButton>(find.byType(MovieLogButton));

    testWidgets('W8-03 이메일·비밀번호를 모두 입력해야 로그인 버튼이 켜진다', (tester) async {
      await pumpLogin(tester);

      expect(location(tester), '/login');
      expect(find.text('MovieLog에 로그인'), findsOneWidget);
      expect(loginButton(tester).onPressed, isNull);

      await tester.enterText(emailField(), 'movie@example.com');
      await tester.pump();
      expect(loginButton(tester).onPressed, isNull);

      await tester.enterText(passwordField(), 'Umc1234!');
      await tester.pump();
      expect(loginButton(tester).onPressed, isNotNull);
    });

    testWidgets('W8-04 요청 중에는 버튼 로딩·입력 잠금, 성공하면 Router가 홈으로 보내고 내 정보를 불러온다', (
      tester,
    ) async {
      final gate = Completer<void>();
      final memberApi = FakeMemberApiService();
      final auth = await pumpLogin(
        tester,
        authApi: FakeAuthApiService(gate: gate.future),
        memberApi: memberApi,
      );

      await tester.enterText(emailField(), 'movie@example.com');
      await tester.enterText(passwordField(), 'Umc1234!');
      await tester.pump();
      await tester.tap(find.byType(MovieLogButton));
      await tester.pump();

      expect(auth.status, AuthStatus.authenticating);
      expect(location(tester), '/login');
      expect(loginButton(tester).isLoading, isTrue);
      expect(tester.widget<TextField>(emailField()).readOnly, isTrue);
      expect(tester.widget<TextField>(passwordField()).readOnly, isTrue);

      gate.complete();
      await tester.pumpAndSettle();

      expect(location(tester), '/home');
      // MainScreen이 처음 열리며 내 정보를 한 번 불러옵니다.
      expect(memberApi.calls, 1);
      expect(auth.member?.nickname, '밍고');
    });

    testWidgets('W8-05 AUTH401_1이면 비밀번호 아래 문구, 입력을 고치면 사라진다', (tester) async {
      await pumpLogin(
        tester,
        authApi: FakeAuthApiService(errorCode: 'AUTH401_1'),
      );

      await tester.enterText(emailField(), 'movie@example.com');
      await tester.enterText(passwordField(), 'wrong-pw');
      await tester.pump();
      final buttonTop = tester.getTopLeft(find.byType(MovieLogButton)).dy;
      await tester.tap(find.byType(MovieLogButton));
      await tester.pumpAndSettle();

      expect(location(tester), '/login');
      expect(find.text('이메일 또는 비밀번호를 확인해 주세요.'), findsOneWidget);
      // 입력값은 유지하고, 문구가 생겨도 버튼 위치는 그대로입니다.
      expect(
        tester.widget<TextField>(passwordField()).controller?.text,
        'wrong-pw',
      );
      expect(tester.getTopLeft(find.byType(MovieLogButton)).dy, buttonTop);
      expect(loginButton(tester).onPressed, isNotNull);

      await tester.enterText(passwordField(), 'Umc1234!');
      await tester.pumpAndSettle(); // 오류 문구가 사라지는 애니메이션까지
      expect(find.text('이메일 또는 비밀번호를 확인해 주세요.'), findsNothing);
    });

    testWidgets('연결 실패는 Snackbar로 안내하고 로그인 화면에 머문다', (tester) async {
      await pumpLogin(
        tester,
        authApi: FakeAuthApiService(connectionError: true),
      );

      await tester.enterText(emailField(), 'movie@example.com');
      await tester.enterText(passwordField(), 'Umc1234!');
      await tester.pump();
      await tester.tap(find.byType(MovieLogButton));
      await tester.pumpAndSettle();

      expect(location(tester), '/login');
      expect(find.text('로그인 요청에 실패했어요. 잠시 후 다시 시도해 주세요.'), findsOneWidget);
    });

    testWidgets('회원가입 링크로 회원가입 화면에 간다', (tester) async {
      await pumpLogin(tester);

      await tester.tap(find.text('회원가입'));
      await tester.pumpAndSettle();

      expect(location(tester), '/register');
    });
  });

  group('세션 만료 안내', () {
    const expiredText = '로그인이 만료됐어요. 다시 로그인해 주세요.';

    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    Future<void> pumpApp(WidgetTester tester, AuthViewModel auth) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MovieLogApp(authViewModel: auth, tmdbMovieService: fakeTmdbService()),
      );
      await tester.pumpAndSettle();
    }

    String location(WidgetTester tester) =>
        appRouter(tester).routerDelegate.currentConfiguration.uri.path;

    testWidgets('보호 화면에서 만료되면 로그인 화면에서 한 번만 안내한다', (tester) async {
      final auth = await signedInAuth();
      await pumpApp(tester, auth);
      appRouter(tester).go('/my');
      await tester.pumpAndSettle();

      await auth.expireSession();
      await tester.pumpAndSettle();

      expect(location(tester), '/login');
      expect(find.text(expiredText), findsOneWidget);
      expect(auth.sessionExpired, isFalse); // 보여준 뒤 꺼짐

      // 다른 상태 변화(입력 오류 지우기 등)로 다시 알려도 반복되지 않습니다.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text(expiredText), findsNothing);
      await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
      await tester.pumpAndSettle();
      expect(find.text(expiredText), findsNothing);
    });

    testWidgets('앱 시작 시 저장 토큰이 만료(AUTH401_4)였으면 로그인 화면이 열리며 안내한다', (
      tester,
    ) async {
      final auth = fakeAuth(
        memberApi: FakeMemberApiService(errorCode: 'AUTH401_4'),
      );
      await auth.initialize(); // 첫 화면이 그려지기 전에 이미 만료 상태
      await pumpApp(tester, auth);

      expect(location(tester), '/login');
      expect(find.text(expiredText), findsOneWidget);
    });

    testWidgets('직접 로그아웃하면 만료 안내를 띄우지 않는다', (tester) async {
      final auth = await signedInAuth();
      await pumpApp(tester, auth);
      appRouter(tester).go('/my');
      await tester.pumpAndSettle();

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      expect(location(tester), '/login');
      expect(find.text(expiredText), findsNothing);
    });

    testWidgets('AUTH401_1 로그인 실패는 만료 안내가 아니라 입력칸 문구만 보여준다', (tester) async {
      final auth = await signedOutAuth(
        authApi: FakeAuthApiService(errorCode: 'AUTH401_1'),
      );
      await pumpApp(tester, auth);

      await tester.enterText(find.byType(TextField).at(0), 'movie@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'wrong');
      await tester.pump();
      await tester.tap(find.byType(MovieLogButton));
      await tester.pumpAndSettle();

      expect(find.text('이메일 또는 비밀번호를 확인해 주세요.'), findsOneWidget);
      expect(find.text(expiredText), findsNothing);
      expect(auth.sessionExpired, isFalse);
    });

    testWidgets('로그아웃 때 토큰 삭제가 실패하면 만료가 아니라 저장소 안내를 한 번 보여준다', (tester) async {
      final storage = InMemoryTokenStorage('token');
      final auth = await signedInAuth(storage: storage);
      storage.failDelete = true;
      await pumpApp(tester, auth);
      appRouter(tester).go('/my');
      await tester.pumpAndSettle();

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      const storageText = '저장된 인증 정보를 지우지 못했어요. 앱 재실행 전에 저장소 상태를 확인해 주세요.';
      expect(location(tester), '/login');
      expect(auth.status, AuthStatus.signedOut); // 메모리 세션은 비움
      expect(find.text(storageText), findsOneWidget);
      expect(find.text(expiredText), findsNothing);
      expect(auth.storageClearFailed, isFalse); // 보여준 뒤 꺼짐

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
      await tester.pumpAndSettle();
      expect(find.text(storageText), findsNothing);
    });

    testWidgets('만료 정리 중 토큰 삭제도 실패하면 저장소 안내 하나만 보여준다', (tester) async {
      final storage = InMemoryTokenStorage('token');
      final auth = await signedInAuth(storage: storage);
      storage.failDelete = true;
      await pumpApp(tester, auth);

      await auth.expireSession();
      await tester.pumpAndSettle();

      expect(
        find.text('저장된 인증 정보를 지우지 못했어요. 앱 재실행 전에 저장소 상태를 확인해 주세요.'),
        findsOneWidget,
      );
      expect(find.text(expiredText), findsNothing);
      expect(auth.sessionExpired, isFalse);
    });

    testWidgets('로그인 직후 홈을 거치지 않고 마이 탭으로 가도 닉네임이 보인다 (MainScreen.loadMember)', (
      tester,
    ) async {
      final memberApi = FakeMemberApiService();
      final loggedIn = fakeAuth(token: null, memberApi: memberApi);
      await loggedIn.initialize();
      await pumpApp(tester, loggedIn);

      await tester.enterText(find.byType(TextField).at(0), 'movie@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'Umc1234!');
      await tester.pump();
      await tester.tap(find.byType(MovieLogButton));
      // 홈이 그려지기 전에 바로 마이 탭으로 이동합니다.
      await tester.pump();
      appRouter(tester).go('/my');
      await tester.pumpAndSettle();

      expect(location(tester), '/my');
      expect(memberApi.calls, 1); // 로그인 후 GET me는 한 번
      expect(loggedIn.member?.nickname, '밍고');
      expect(find.text('밍고'), findsOneWidget);
    });
  });
}
