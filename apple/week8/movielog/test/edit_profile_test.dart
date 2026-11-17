import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/edit_profile_view_model.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/widgets/movielog_button.dart';

import 'fake_auth.dart';
import 'fake_tmdb.dart';

void main() {
  group('EditProfileViewModel.save', () {
    late FakeMemberApiService api;
    late InMemoryTokenStorage storage;
    late AuthViewModel auth;
    late EditProfileViewModel viewModel;

    setUp(() async {
      api = FakeMemberApiService();
      storage = InMemoryTokenStorage('token');
      auth = await signedInAuth(memberApi: api, storage: storage);
      viewModel = EditProfileViewModel(api, auth);
    });

    test('성공하면 AuthViewModel.member를 응답으로 교체한다', () async {
      final ok = await viewModel.save('  새닉네임 ');

      expect(ok, isTrue);
      expect(api.nicknameRequests, ['새닉네임']);
      expect(auth.member?.nickname, '새닉네임');
      expect(viewModel.status, EditProfileStatus.success);
    });

    test('2~12자가 아니면 요청 없이 입력칸 오류', () async {
      expect(await viewModel.save('a'), isFalse);
      expect(viewModel.nicknameError, '닉네임은 2~12자로 입력해 주세요.');
      expect(api.nicknameRequests, isEmpty);
    });

    test('현재 닉네임과 같으면 요청 없이 완료', () async {
      expect(await viewModel.save('밍고'), isTrue);
      expect(api.nicknameRequests, isEmpty);
    });

    test('MEMBER409_1이면 중복 문구를 입력칸 아래에 남기고 세션은 유지한다', () async {
      api.updateErrorCode = 'MEMBER409_1';

      expect(await viewModel.save('무비러버'), isFalse);

      expect(viewModel.nicknameError, '이미 사용 중인 닉네임이에요.');
      expect(viewModel.message, isNull);
      expect(auth.status, AuthStatus.signedIn);
      expect(auth.member?.nickname, '밍고');
    });

    test('COMMON400이면 서버 message를 입력칸 아래에 그대로 보여준다', () async {
      api
        ..updateErrorCode = 'COMMON400'
        ..updateErrorStatus = 400;

      await viewModel.save('무비러버');

      expect(viewModel.nicknameError, 'server message for COMMON400');
    });

    test('AUTH401_4면 세션을 만료로 정리한다', () async {
      api
        ..updateErrorCode = 'AUTH401_4'
        ..updateErrorStatus = 401;

      expect(await viewModel.save('무비러버'), isFalse);

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.sessionExpired, isTrue);
      expect(storage.token, isNull);
    });

    test('네트워크 실패는 로그아웃하지 않고 Snackbar 문구만 남긴다', () async {
      api.updateConnectionError = true;

      expect(await viewModel.save('무비러버'), isFalse);

      expect(viewModel.message, '네트워크 상태를 확인하고 다시 시도해 주세요.');
      expect(viewModel.nicknameError, isNull);
      expect(auth.status, AuthStatus.signedIn);
      expect(storage.token, 'token');
    });

    test('저장 중에 다시 눌러도 한 번만 보낸다', () async {
      final gate = Completer<void>();
      api.updateGate = gate.future;

      final first = viewModel.save('무비러버');
      expect(viewModel.isSaving, isTrue);
      expect(await viewModel.save('무비러버'), isFalse);
      gate.complete();
      await first;

      expect(api.nicknameRequests, hasLength(1));
    });

    test('저장 중 로그아웃하면 늦게 온 성공 응답을 반영하지 않는다', () async {
      final gate = Completer<void>();
      api.updateGate = gate.future;

      final pending = viewModel.save('무비러버');
      await auth.logout();
      gate.complete();

      expect(await pending, isFalse);
      expect(auth.member, isNull);
      expect(auth.status, AuthStatus.signedOut);
    });
  });

  test('logout은 만료 안내 없이 토큰과 내 정보를 비운다', () async {
    final storage = InMemoryTokenStorage('token');
    final auth = await signedInAuth(storage: storage);

    await auth.logout();

    expect(auth.status, AuthStatus.signedOut);
    expect(auth.sessionExpired, isFalse);
    expect(auth.member, isNull);
    expect(storage.token, isNull);
  });

  group('마이페이지 · 프로필 수정 화면', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    Future<(AuthViewModel, FakeMemberApiService, InMemoryTokenStorage)> pumpMy(
      WidgetTester tester, {
      LearningMemberSession? learningMemberSession,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final api = FakeMemberApiService();
      final storage = InMemoryTokenStorage('token');
      final auth = await signedInAuth(memberApi: api, storage: storage);
      await tester.pumpWidget(
        MovieLogApp(
          authViewModel: auth,
          memberApiService: api,
          tmdbMovieService: fakeTmdbService(),
          learningMemberSession: learningMemberSession,
        ),
      );
      await tester.pumpAndSettle();
      appRouter(tester).go('/my');
      await tester.pumpAndSettle();
      return (auth, api, storage);
    }

    String location(WidgetTester tester) =>
        appRouter(tester)
            .routerDelegate
            .currentConfiguration
            .last
            .matchedLocation;

    Finder nicknameField() => find.byType(TextField).at(1);

    Future<void> openEdit(WidgetTester tester) async {
      await tester.tap(find.text('프로필 수정'));
      await tester.pumpAndSettle();
    }

    testWidgets('W8-06 로그아웃하면 Router가 로그인 화면으로 보낸다', (tester) async {
      final learning = LearningMemberSession()..setMemberId(42);
      final (auth, _, storage) = await pumpMy(
        tester,
        learningMemberSession: learning,
      );

      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      expect(location(tester), '/login');
      expect(auth.status, AuthStatus.signedOut);
      expect(storage.token, isNull);
      // 이전 계정의 학습용 memberId가 다음 로그인에 남지 않습니다.
      expect(learning.memberId, isNull);
    });

    testWidgets('W8-07 현재 이메일·닉네임과 글자 수를 보여주고, 저장하면 마이페이지에 바로 반영된다', (
      tester,
    ) async {
      final (_, api, _) = await pumpMy(tester);
      await openEdit(tester);

      expect(location(tester), '/my/profile/edit');
      expect(find.text('이메일 (변경할 수 없습니다)'), findsOneWidget);
      expect(find.text('mingo@example.com'), findsOneWidget);
      expect(find.text('2 / 12'), findsOneWidget);
      // 이메일은 수정할 수 없습니다.
      expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).enabled,
        isFalse,
      );

      await tester.enterText(nicknameField(), '무비러버');
      await tester.pump();
      expect(find.text('4 / 12'), findsOneWidget);

      await tester.tap(find.byType(MovieLogButton));
      await tester.pumpAndSettle();

      expect(api.nicknameRequests, ['무비러버']);
      expect(location(tester), '/my');
      expect(find.text('프로필을 수정했어요.'), findsOneWidget);
      expect(find.text('무비러버'), findsOneWidget);
    });

    testWidgets('W8-08 저장 중에는 버튼 로딩·입력 잠금·뒤로가기 막기', (tester) async {
      final (_, api, _) = await pumpMy(tester);
      final gate = Completer<void>();
      api.updateGate = gate.future;
      await openEdit(tester);

      await tester.enterText(nicknameField(), '무비러버');
      await tester.tap(find.byType(MovieLogButton));
      await tester.pump();

      expect(
        tester.widget<MovieLogButton>(find.byType(MovieLogButton)).isLoading,
        isTrue,
      );
      expect(tester.widget<TextField>(nicknameField()).readOnly, isTrue);

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(location(tester), '/my/profile/edit');

      gate.complete();
      await tester.pumpAndSettle();
      expect(location(tester), '/my');
    });

    testWidgets('W8-09 닉네임 중복이면 입력값을 유지하고 문구를 보여주며, 고치면 사라진다', (tester) async {
      final (_, api, _) = await pumpMy(tester);
      api.updateErrorCode = 'MEMBER409_1';
      await openEdit(tester);

      await tester.enterText(nicknameField(), '무비러버');
      await tester.tap(find.byType(MovieLogButton));
      await tester.pumpAndSettle();

      expect(location(tester), '/my/profile/edit');
      expect(find.text('이미 사용 중인 닉네임이에요.'), findsOneWidget);
      expect(find.text('4 / 12'), findsOneWidget);
      expect(
        tester.widget<TextField>(nicknameField()).controller?.text,
        '무비러버',
      );

      await tester.enterText(nicknameField(), '무비러버2');
      await tester.pump();
      expect(find.text('이미 사용 중인 닉네임이에요.'), findsNothing);
    });

    testWidgets('네트워크 실패는 Snackbar로 알리고 화면에 남는다', (tester) async {
      final (auth, api, _) = await pumpMy(tester);
      api.updateConnectionError = true;
      await openEdit(tester);

      await tester.enterText(nicknameField(), '무비러버');
      await tester.tap(find.byType(MovieLogButton));
      await tester.pumpAndSettle();

      expect(location(tester), '/my/profile/edit');
      expect(find.text('네트워크 상태를 확인하고 다시 시도해 주세요.'), findsOneWidget);
      expect(auth.status, AuthStatus.signedIn);
    });

    testWidgets('저장 중 401이면 세션을 정리하고 Router가 로그인 화면으로 보낸다', (tester) async {
      final (_, api, _) = await pumpMy(tester);
      api
        ..updateErrorCode = 'AUTH401_3'
        ..updateErrorStatus = 401;
      await openEdit(tester);

      await tester.enterText(nicknameField(), '무비러버');
      await tester.tap(find.byType(MovieLogButton));
      await tester.pumpAndSettle();

      expect(location(tester), '/login');
    });
  });
}
