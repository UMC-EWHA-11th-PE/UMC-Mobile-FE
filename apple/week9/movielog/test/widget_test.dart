import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/widgets/movie_card.dart';

import 'fake_sign_up.dart';
import 'fake_ratings.dart';
import 'fake_auth.dart';
import 'fake_favorites.dart';
import 'fake_tmdb.dart';

void main() {
  setUp(() {
    // 영화 목록이 마지막 선택 장르를 읽으므로 메모리 저장소로 대체
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('로그아웃 상태면 로그인 → 회원가입으로 이동하고, 회원가입 뒤로가기·가입 완료는 로그인 화면으로 간다', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: FakeFavoriteServer().service,
        authViewModel: await signedOutAuth(),
        tmdbMovieService: fakeTmdbService(),
        signUpService: fakeSignUpService(),
      ),
    );
    await tester.pumpAndSettle();

    String location() =>
        appRouter(tester).routerDelegate.currentConfiguration.uri.path;

    // 토큰이 없으므로 스플래시(/start)에서 로그인 화면으로 redirect
    expect(location(), '/login');
    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();

    // 회원가입: 쌓인 화면은 없지만 헤더 뒤로가기는 로그인 화면으로 이동
    expect(location(), '/register');
    expect(find.text('환영합니다!'), findsOneWidget);
    expect(find.text('간단한 정보만 입력하고 시작해보세요.'), findsOneWidget);
    expect(appRouter(tester).canPop(), isFalse);
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(location(), '/login');

    // 시스템 뒤로가기(Android 뒤로 버튼)도 로그인 화면으로 이동
    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(location(), '/login');

    // 로그아웃 상태에서 보호 화면으로 가려 해도 로그인 화면에 머묾
    appRouter(tester).go('/movies');
    await tester.pumpAndSettle();
    expect(location(), '/login');

    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();

    // 검증 전에는 가입하기 비활성
    ElevatedButton submitButton() => tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('가입하기'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(submitButton().onPressed, isNull);

    // 닉네임·이메일·비밀번호 입력 + 약관 동의
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '밍고');
    await tester.enterText(fields.at(1), 'mingo@example.com');
    await tester.enterText(fields.at(2), 'Password1!');
    await tester.ensureVisible(find.text('필수 약관에 동의합니다'));
    await tester.tap(find.text('필수 약관에 동의합니다'));
    await tester.pumpAndSettle();
    // 중복 확인 전에는 아직 비활성
    expect(submitButton().onPressed, isNull);

    // 닉네임·이메일 중복 확인 → 가입하기 활성
    final checkButtons = find.text('중복 확인');
    await tester.tap(checkButtons.at(0));
    await tester.tap(checkButtons.at(1));
    await tester.pumpAndSettle();
    expect(find.text('사용 가능한 닉네임입니다.'), findsOneWidget);
    expect(find.text('사용 가능한 이메일입니다.'), findsOneWidget);
    expect(submitButton().onPressed, isNotNull);

    await tester.ensureVisible(find.text('가입하기'));
    await tester.tap(find.text('가입하기'));
    await tester.pumpAndSettle();

    // 가입만으로는 JWT가 없으므로 로그인 화면(/login) 도착 + 가입 완료 안내
    expect(location(), '/login');
    expect(find.text('회원가입이 완료되었습니다.'), findsOneWidget);
    expect(appRouter(tester).canPop(), isFalse);
  });

  testWidgets('홈 인기 영화 카드를 누르면 같은 ID의 영화 상세로 이동한다', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: FakeFavoriteServer().service,
        authViewModel: await signedInAuth(),
        tmdbMovieService: fakeTmdbService(),
      ),
    );
    await tester.pumpAndSettle();
    appRouter(tester).go('/home');
    await tester.pumpAndSettle();

    await tester.tap(find.text('마션 레스큐'));
    await tester.pumpAndSettle();
    expect(find.text('Cinema Archive'), findsOneWidget);
    expect(find.text('마션 레스큐'), findsOneWidget);
    // push로 쌓인 맨 위 화면의 경로
    expect(
      appRouter(tester)
          .routerDelegate
          .currentConfiguration
          .last
          .matchedLocation,
      '/movies/7',
    );

    // 상세에서 뒤로가기 → 홈
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(find.text('오늘은 어떤\n영화를 볼까요?'), findsOneWidget);
  });

  testWidgets('별빛 아래 우리는 홈·목록·상세에서 같은 ID(1)와 제목을 쓴다', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // push로 쌓인 맨 위 화면의 경로
    String currentPath() =>
        appRouter(tester)
            .routerDelegate
            .currentConfiguration
            .last
            .matchedLocation;

    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: FakeFavoriteServer().service,
        authViewModel: await signedInAuth(),
        tmdbMovieService: fakeTmdbService(),
      ),
    );
    await tester.pumpAndSettle();

    // 홈 배너 → 상세 (장르·러닝타임도 상세와 같은 Mock)
    appRouter(tester).go('/home');
    await tester.pumpAndSettle();
    expect(find.text('별빛 아래 우리'), findsOneWidget);
    expect(find.text('로맨스 · 드라마 · 124분'), findsOneWidget);
    await tester.tap(find.text('상세보기'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/movies/1');
    expect(find.text('별빛 아래 우리'), findsOneWidget);

    // 목록 카드 → 상세
    appRouter(tester).go('/movies');
    await tester.pumpAndSettle();
    await tester.tap(find.text('별빛 아래 우리'));
    await tester.pumpAndSettle();
    expect(currentPath(), '/movies/1');
    expect(find.text('별빛 아래 우리'), findsOneWidget);
  });

  testWidgets('하단 탭으로 홈/영화/마이를 이동한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: FakeFavoriteServer().service,
        authViewModel: await signedInAuth(),
        tmdbMovieService: fakeTmdbService(),
      ),
    );
    await tester.pumpAndSettle();

    appRouter(tester).go('/home');
    await tester.pumpAndSettle();
    // Material 3 NavigationBar로 탭을 전환
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('오늘은 어떤\n영화를 볼까요?'), findsOneWidget);

    await tester.tap(find.text('영화'));
    await tester.pumpAndSettle();
    expect(find.text('별빛 아래 우리'), findsOneWidget);
    expect(find.text('우주의 끝에서'), findsOneWidget);

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    expect(find.text('밍고'), findsOneWidget); // /members/me 닉네임
  });

  testWidgets('하단 네비게이션이 Figma 크기를 따른다', (WidgetTester tester) async {
    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: FakeFavoriteServer().service,
        authViewModel: await signedInAuth(),
        tmdbMovieService: fakeTmdbService(),
      ),
    );
    await tester.pumpAndSettle();
    appRouter(tester).go('/home');
    await tester.pumpAndSettle();

    // 라벨을 감싸는 pill(StadiumBorder Material)의 크기
    Size pillSize(String label) => tester.getSize(
      find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate(
          (widget) => widget is Material && widget.shape is StadiumBorder,
        ),
      ),
    );

    // 선택된 홈: 56 x 40.8
    expect(pillSize('홈'), const Size(56, 40.8));
    // 미선택 마이: 높이 44 (너비는 글꼴에 따라 달라짐)
    expect(pillSize('마이').height, 44);
  });

  testWidgets('홈 헤더가 Figma 크기를 따른다', (WidgetTester tester) async {
    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: FakeFavoriteServer().service,
        authViewModel: await signedInAuth(),
        tmdbMovieService: fakeTmdbService(),
      ),
    );
    await tester.pumpAndSettle();
    appRouter(tester).go('/home');
    await tester.pumpAndSettle();

    expect(find.text('MovieLog'), findsOneWidget);
    // 로고 높이 28 (line-height)
    expect(tester.getSize(find.text('MovieLog')).height, 28);
    // 검색 버튼 34 x 34, 오른쪽 여백 16
    final search = find.byTooltip('검색');
    expect(tester.getSize(search), const Size(34, 34));
    expect(tester.getTopRight(search).dx, 800 - 16);
  });

  testWidgets('홈 인사말·배너가 Figma 크기를 따른다', (WidgetTester tester) async {
    // Figma 프레임 내부 너비 388에 맞춰 화면 크기를 고정
    tester.view.physicalSize = const Size(388, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: FakeFavoriteServer().service,
        authViewModel: await signedInAuth(),
        tmdbMovieService: fakeTmdbService(),
      ),
    );
    await tester.pumpAndSettle();
    appRouter(tester).go('/home');
    await tester.pumpAndSettle();

    // greeting section 388 x 104
    final greeting = find.text('오늘은 어떤\n영화를 볼까요?');
    expect(tester.getSize(greeting), const Size(356, 72));

    // 배너 356 x 534, 인사말 바로 아래(좌우 16)
    final banner = find.ancestor(
      of: find.text('별빛 아래 우리'),
      matching: find.byType(ClipRRect),
    );
    expect(tester.getSize(banner), const Size(356, 534));
    expect(
      tester.getTopLeft(banner) - tester.getTopLeft(greeting),
      const Offset(0, 72 + 16),
    );

    // 상세보기 버튼 308 x 48, 배너 하단에서 24 위
    final button = find.ancestor(
      of: find.text('상세보기'),
      matching: find.byType(InkWell),
    );
    expect(tester.getSize(button), const Size(308, 48));
    expect(
      tester.getBottomLeft(banner).dy - tester.getBottomLeft(button).dy,
      24,
    );

    // 추천 신작 칩 높이 34 (너비는 글꼴에 따라 달라짐)
    final chip = find.ancestor(
      of: find.text('추천 신작'),
      matching: find.byType(BackdropFilter),
    );
    expect(tester.getSize(chip).height, 34);

    // 배너 하단 영역 218 = 칩부터 버튼까지 + padding 24 x 2
    expect(
      tester.getBottomLeft(banner).dy - tester.getTopLeft(chip).dy,
      218 - 24,
    );
  });

  testWidgets('인기 영화 섹션이 Figma 크기를 따른다', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(388, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: FakeFavoriteServer().service,
        authViewModel: await signedInAuth(),
        tmdbMovieService: fakeTmdbService(),
      ),
    );
    await tester.pumpAndSettle();
    appRouter(tester).go('/home');
    await tester.pumpAndSettle();

    // 섹션 제목 줄 높이 28, 배너 섹션(padding-bottom 24) 바로 아래
    final title = find.text('인기 영화');
    expect(tester.getSize(title).height, 28);
    final banner = find.ancestor(
      of: find.text('별빛 아래 우리'),
      matching: find.byType(ClipRRect),
    );
    expect(tester.getTopLeft(title).dy - tester.getBottomLeft(banner).dy, 24);

    // 카드 140 x 256, 제목 줄과 gap 16
    final card = find.ancestor(
      of: find.text('마션 레스큐'),
      matching: find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.width == 140,
      ),
    );
    expect(tester.getSize(card), const Size(140, 256));
    expect(tester.getTopLeft(card).dy - tester.getBottomLeft(title).dy, 16);

    // 포스터 140 x 200, 순위 칩은 포스터 왼쪽 위에서 8, 높이 26
    final poster = find
        .ancestor(of: find.text('1'), matching: find.byType(ClipRRect))
        .last;
    expect(tester.getSize(poster), const Size(140, 200));
    final rankChip = find.ancestor(
      of: find.text('1'),
      matching: find.byType(BackdropFilter),
    );
    expect(
      tester.getTopLeft(rankChip) - tester.getTopLeft(poster),
      const Offset(8, 8),
    );
    expect(tester.getSize(rankChip).height, 26);

    // 다음 카드와 간격 16
    final secondCard = find.ancestor(
      of: find.text('스파이 코드'),
      matching: find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.width == 140,
      ),
    );
    expect(tester.getTopLeft(secondCard).dx - tester.getTopRight(card).dx, 16);

    // 별점 표시
    expect(find.text('9.6'), findsOneWidget);
  });

  testWidgets('홈이 다시 그려지거나 상세에서 돌아와도 Popular를 다시 요청하지 않는다', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final requests = <Uri>[];
    int popularCount() =>
        requests.where((uri) => uri.path.endsWith('/movie/popular')).length;

    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: FakeFavoriteServer().service,
        authViewModel: await signedInAuth(),
        tmdbMovieService: fakeTmdbService(requests: requests),
      ),
    );
    await tester.pumpAndSettle();
    appRouter(tester).go('/home');
    await tester.pumpAndSettle();
    expect(popularCount(), 1);

    // 화면 크기가 바뀌어 홈 전체가 다시 build 되어도 요청하지 않음
    tester.view.physicalSize = const Size(400, 1200);
    await tester.pumpAndSettle();
    expect(popularCount(), 1);

    // 인기 영화 카드 → 상세 → 뒤로가기 (홈은 그대로 유지)
    await tester.tap(find.text('마션 레스큐'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(popularCount(), 1);
    expect(find.text('마션 레스큐'), findsOneWidget);
  });

  testWidgets('전체보기를 누르면 영화 탭으로 이동한다', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(388, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: FakeFavoriteServer().service,
        authViewModel: await signedInAuth(),
        tmdbMovieService: fakeTmdbService(),
      ),
    );
    await tester.pumpAndSettle();
    appRouter(tester).go('/home');
    await tester.pumpAndSettle();

    await tester.tap(find.text('전체보기'));
    await tester.pumpAndSettle();
    expect(find.text('우주의 끝에서'), findsOneWidget);
  });

  group('영화 목록', () {
    Future<void> openMovieList(WidgetTester tester) async {
      // W3-02 Figma 프레임 너비 390 (콘텐츠 358 = 390 - 16 x 2)
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MovieLogApp(
          favoriteApiService: FakeFavoriteServer().service,
          authViewModel: await signedInAuth(),
          tmdbMovieService: fakeTmdbService(),
        ),
      );
      await tester.pumpAndSettle();
      appRouter(tester).go('/home');
      await tester.pumpAndSettle();
      await tester.tap(find.text('영화'));
      await tester.pumpAndSettle();
    }

    Finder itemOf(String title) =>
        find.ancestor(of: find.text(title), matching: find.byType(MovieCard));

    testWidgets('Figma 크기를 따른다', (WidgetTester tester) async {
      await openMovieList(tester);

      // 헤더 제목
      expect(find.text('영화'), findsNWidgets(2)); // 헤더 + 하단 네비

      // 필터 칩 높이 32, 헤더 아래 8
      final allChip = find
          .ancestor(of: find.text('전체'), matching: find.byType(Material))
          .first;
      expect(tester.getSize(allChip).height, 32);
      expect(tester.getTopLeft(allChip), const Offset(16, 64 + 8));

      // 영화 아이템 171 x 316.5, 포스터 171 x 256.5
      final first = itemOf('별빛 아래 우리');
      final second = itemOf('우주의 끝에서');
      final third = itemOf('기억의 숲');
      expect(tester.getSize(first), const Size(171, 316.5));
      final poster = find.ancestor(
        of: find.text('★ 4.8'),
        matching: find.byType(AspectRatio),
      );
      expect(tester.getSize(poster), const Size(171, 256.5));

      // 필터 칩 영역(40) 아래 16에서 그리드 시작
      expect(tester.getTopLeft(first).dy, 64 + 8 + 40 + 16);

      // column-gap 16, row-gap 24
      expect(tester.getTopLeft(second).dx - tester.getTopRight(first).dx, 16);
      expect(tester.getTopLeft(third).dy - tester.getBottomLeft(first).dy, 24);

      // 별점 칩: 포스터 오른쪽 위에서 8, 높이 24
      final ratingChip = find.ancestor(
        of: find.text('★ 4.8'),
        matching: find.byType(BackdropFilter),
      );
      expect(
        tester.getTopRight(ratingChip) - tester.getTopRight(poster),
        const Offset(-8, 8),
      );
      expect(tester.getSize(ratingChip).height, 24);

      // 소제목
      expect(find.text('2023 · 드라마'), findsOneWidget);
    });

    testWidgets('장르 칩을 누르면 해당 장르만 보인다', (WidgetTester tester) async {
      await openMovieList(tester);

      await tester.tap(find.text('SF'));
      await tester.pumpAndSettle();
      expect(find.text('우주의 끝에서'), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsNothing);

      await tester.tap(find.text('전체'));
      await tester.pumpAndSettle();
      expect(find.text('별빛 아래 우리'), findsOneWidget);
    });
  });

  group('영화 상세', () {
    Future<void> openDetail(WidgetTester tester) async {
      // W3-03 Figma 프레임 너비 390
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MovieLogApp(
          favoriteApiService: FakeFavoriteServer().service,
          authViewModel: await signedInAuth(),
          tmdbMovieService: fakeTmdbService(),
        ),
      );
      await tester.pumpAndSettle();
      appRouter(tester).go('/home');
      await tester.pumpAndSettle();
      // 홈 추천 신작(Mock 상세, Figma W3-03 내용)으로 상세 이동
      await tester.tap(find.text('상세보기'));
      await tester.pumpAndSettle();
    }

    testWidgets('Figma 크기와 내용을 따른다', (WidgetTester tester) async {
      await openDetail(tester);

      expect(find.text('Cinema Archive'), findsOneWidget);
      // 상세는 하단 탭 없이 전체 화면
      expect(find.text('마이'), findsNothing);

      // 히어로 390 x 585, 헤더(64) 바로 아래
      final hero = find.byType(AspectRatio);
      expect(tester.getSize(hero), const Size(390, 585));
      expect(tester.getTopLeft(hero), const Offset(0, 64));

      // 인포 섹션: 제목은 히어로 아래 24, 왼쪽 16
      final title = find.text('별빛 아래 우리');
      expect(tester.getTopLeft(title), const Offset(16, 64 + 585 + 24));
      expect(tester.getSize(title).height, 36);
      expect(find.text('2024 • 로맨스/드라마 • 124분'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('(1,245)'), findsOneWidget);

      // 장르 칩 높이 28
      expect(tester.getSize(find.text('감동적인').hitTestable()).height, 20);
      final chip = find
          .ancestor(of: find.text('감동적인'), matching: find.byType(Container))
          .first;
      expect(tester.getSize(chip).height, 28);

      // 인포 섹션 216 → 시놉시스는 히어로 아래 216에서 시작 (padding 16 + border 1)
      final synopsisTitle = find.text('시놉시스');
      expect(tester.getTopLeft(synopsisTitle).dy, 64 + 585 + 216 + 1 + 16);

      // 하단 고정 버튼: 높이 48, 영역 높이 81
      final bookmark = find.ancestor(
        of: find.text('즐겨찾기'),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(bookmark).height, 48);
      expect(1400 - tester.getTopLeft(bookmark).dy, 48 + 16);
      final actionBar = find
          .ancestor(of: bookmark, matching: find.byType(SafeArea))
          .first;
      expect(
        tester
            .getSize(
              find
                  .ancestor(of: actionBar, matching: find.byType(Container))
                  .first,
            )
            .height,
        81,
      );
    });

    testWidgets('목록에서 연 상세에서 뒤로가기를 누르면 영화 목록으로 돌아간다', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MovieLogApp(
          favoriteApiService: FakeFavoriteServer().service,
          authViewModel: await signedInAuth(),
          tmdbMovieService: fakeTmdbService(),
        ),
      );
      await tester.pumpAndSettle();
      appRouter(tester).go('/movies');
      await tester.pumpAndSettle();
      await tester.tap(find.text('별빛 아래 우리'));
      await tester.pumpAndSettle();
      expect(find.text('Cinema Archive'), findsOneWidget);

      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();
      expect(find.text('Cinema Archive'), findsNothing);
      expect(find.text('우주의 끝에서'), findsOneWidget);
    });

    testWidgets('추천 신작(Mock 영화)은 TMDB id가 아니라 서버 즐겨찾기에 등록하지 않는다', (
      WidgetTester tester,
    ) async {
      await openDetail(tester);

      await tester.tap(find.text('즐겨찾기'));
      await tester.pump();
      expect(find.text('예시 영화는 즐겨찾기할 수 없습니다.'), findsOneWidget);
      // 등록되지 않았으므로 채워진 북마크(PNG)는 보이지 않습니다.
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/icons/bookmark_filled.png',
        ),
        findsNothing,
      );
    });

    testWidgets('추천 신작(Mock 영화)은 TMDB id가 아니라 서버에 평점을 남기지 않는다', (
      WidgetTester tester,
    ) async {
      await openDetail(tester);

      await tester.tap(find.text('평점 남기기'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('예시 영화에는 평점을 남길 수 없습니다.'), findsOneWidget);
    });
  });

  testWidgets('영화 상세에서 평점을 등록하면 Snackbar가 뜨고, 마이페이지 목록에서 다시 조회된다', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final server = FakeRatingServer();
    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: FakeFavoriteServer().service,
        authViewModel: await signedInAuth(),
        tmdbMovieService: fakeTmdbService(),
        ratingApiService: server.service,
        learningMemberSession: LearningMemberSession()
          ..setMember(42, 'mingo@example.com'),
      ),
    );
    await tester.pumpAndSettle();
    appRouter(tester).go('/movies/1');
    await tester.pumpAndSettle();

    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    final dialogStar = find
        .descendant(of: find.byType(Dialog), matching: find.byType(SvgPicture))
        .at(3);
    await tester.tap(dialogStar);
    await tester.enterText(find.byType(TextField), '별이 예뻐요');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    // memberId 없이 TMDB id로 등록 (회원은 JWT로 식별)
    expect(server.calls, ['POST /v8/ratings']);
    expect(server.bodies.single, {
      'movieId': 1,
      'score': 4,
      'comment': '별이 예뻐요',
    });
    expect(find.byType(Dialog), findsNothing);
    expect(
      find.text('평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.'),
      findsOneWidget,
    );

    // 마이페이지 → 내가 등록한 평점에서 GET으로 다시 확인
    appRouter(tester).go('/my');
    await tester.pumpAndSettle();
    await tester.tap(find.text('내가 등록한 평점'));
    await tester.pumpAndSettle();
    expect(server.calls.last, 'GET /v8/members/42/ratings');
    expect(find.text('별빛 아래 우리'), findsOneWidget);
    expect(find.text('별점 4 / 5'), findsOneWidget);
    expect(find.text('별이 예뻐요'), findsOneWidget);
  });

  testWidgets('홈 배너 상세보기를 누르면 영화 상세로 이동한다', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: FakeFavoriteServer().service,
        authViewModel: await signedInAuth(),
        tmdbMovieService: fakeTmdbService(),
      ),
    );
    await tester.pumpAndSettle();
    appRouter(tester).go('/home');
    await tester.pumpAndSettle();

    await tester.tap(find.text('상세보기'));
    await tester.pumpAndSettle();
    expect(find.text('Cinema Archive'), findsOneWidget);
    expect(find.text('(1,245)'), findsOneWidget);
  });

  testWidgets('다른 계정으로 가입한 memberId는 쓰지 않고, 이번 세션에 등록한 평점만 보여주고 수정한다', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final server = FakeRatingServer(
      // 공개 조회를 했다면 보였을 다른 회원(42)의 평점
      ratings: [fakeRatingJson(ratingId: 9, movieId: 2, comment: '남의 평점')],
    );
    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: FakeFavoriteServer().service,
        authViewModel: await signedInAuth(),
        tmdbMovieService: fakeTmdbService(),
        ratingApiService: server.service,
        // 로그인한 계정(mingo@example.com)과 다른 email로 가입한 기록
        learningMemberSession: LearningMemberSession()
          ..setMember(42, 'other@example.com'),
      ),
    );
    await tester.pumpAndSettle();

    // 영화 상세에서 등록 → 응답 평점을 이번 세션에 보관
    appRouter(tester).go('/movies/1');
    await tester.pumpAndSettle();
    await tester.tap(find.text('평점 남기기'));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(Dialog),
            matching: find.byType(SvgPicture),
          )
          .at(3),
    );
    await tester.pump(); // 별점이 반영돼 확인 버튼이 켜진 프레임
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    appRouter(tester).go('/my');
    await tester.pumpAndSettle();
    await tester.tap(find.text('내가 등록한 평점'));
    await tester.pumpAndSettle();

    // 다른 회원의 memberId로 공개 조회하지 않습니다.
    expect(server.calls, ['POST /v8/ratings']);
    expect(find.text('남의 평점'), findsNothing);
    expect(find.text('별빛 아래 우리'), findsOneWidget);
    expect(
      find.text('이번 로그인에서 등록한 평점만 보여요.\n이전에 남긴 평점은 아직 불러올 수 없어요.'),
      findsOneWidget,
    );

    // 이번 세션 등록분은 JWT로 수정할 수 있습니다. (memberId 없음)
    await tester.tap(find.text('수정'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      ),
      '다시 봐도 좋다',
    );
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(server.calls.last, startsWith('PATCH /v8/ratings/'));
    expect(find.text('다시 봐도 좋다'), findsOneWidget);
  });

  testWidgets('마이 → 내가 등록한 평점은 하단 탭 없이 열리고, 뒤로가면 마이로 돌아온다', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final requests = <String>[];
    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: FakeFavoriteServer().service,
        authViewModel: await signedInAuth(),
        tmdbMovieService: fakeTmdbService(),
        ratingApiService: fakeRatingApiService(
          ratings: [fakeRatingJson(movieId: 1)],
          requests: requests,
        ),
        learningMemberSession: LearningMemberSession()
          ..setMember(42, 'mingo@example.com'),
      ),
    );
    await tester.pumpAndSettle();
    appRouter(tester).go('/my');
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('내가 등록한 평점'));
    await tester.pumpAndSettle();
    expect(
      appRouter(tester)
          .routerDelegate
          .currentConfiguration
          .last
          .matchedLocation,
      '/my/ratings',
    );
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('별빛 아래 우리'), findsOneWidget);
    // 같은 계정으로 가입한 memberId일 때만 공개 조회
    expect(requests, ['/v8/members/42/ratings']);

    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('내 프로필'), findsOneWidget);
  });

  testWidgets('마이 탭에 내 정보(닉네임·이메일)와 로그아웃 버튼이 나온다 (W8-06)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: FakeFavoriteServer().service,
        authViewModel: await signedInAuth(),
        tmdbMovieService: fakeTmdbService(),
      ),
    );
    await tester.pumpAndSettle();
    appRouter(tester).go('/home');
    await tester.pumpAndSettle();
    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();

    // 헤더와 내용
    expect(find.text('내 프로필'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('밍고'), findsOneWidget); // /members/me 닉네임
    expect(find.text('mingo@example.com'), findsOneWidget);
    expect(find.text('프로필 수정'), findsOneWidget);
    for (final text in ['342', '4.2', '58', '본 영화', '평점', '즐겨찾기']) {
      expect(find.text(text), findsOneWidget);
    }

    // 프로필 사진 128 x 128, 헤더 아래 24
    final avatar = find
        .ancestor(of: find.byType(ClipOval), matching: find.byType(Container))
        .first;
    expect(tester.getSize(avatar), const Size(128, 128));
    expect(tester.getTopLeft(avatar).dy, 64 + 24);

    // 프로필 수정 버튼 높이 42
    final editButton = find.ancestor(
      of: find.text('프로필 수정'),
      matching: find.byType(TextButton),
    );
    expect(tester.getSize(editButton).height, 42);

    // 통계 카드 3개가 같은 너비 (358 - 8 x 2) / 3
    final statCard = find
        .ancestor(of: find.text('342'), matching: find.byType(Container))
        .first;
    expect(tester.getSize(statCard).width, closeTo((358 - 16) / 3, 0.01));

    // 선호 장르 칩 높이 32
    final chip = find
        .ancestor(of: find.text('애니메이션'), matching: find.byType(Container))
        .first;
    expect(tester.getSize(chip).height, 32);

    // 내가 등록한 평점 카드 358 x 64 — 통계 아래 26, 선호하는 장르 위 28 (W6-ENTRY)
    final entry = find
        .ancestor(of: find.text('내가 등록한 평점'), matching: find.byType(Material))
        .first;
    expect(tester.getSize(entry), const Size(358, 64));
    expect(tester.getTopLeft(entry).dy - tester.getBottomLeft(statCard).dy, 26);
    // W9 — 내 즐겨찾기 행은 내가 등록한 평점 아래 8, 같은 크기. 선호하는 장르는 그 아래 28
    final favoritesEntry = find
        .ancestor(of: find.text('내 즐겨찾기'), matching: find.byType(Material))
        .first;
    expect(tester.getSize(favoritesEntry), const Size(358, 64));
    expect(
      tester.getTopLeft(favoritesEntry).dy - tester.getBottomLeft(entry).dy,
      8,
    );
    expect(
      tester.getTopLeft(find.text('선호하는 장르')).dy -
          tester.getBottomLeft(favoritesEntry).dy,
      28,
    );
    // 글자 왼쪽 19, 꺾쇠 8 x 14 오른쪽 18
    expect(
      tester.getTopLeft(find.text('내가 등록한 평점')).dx -
          tester.getTopLeft(entry).dx,
      19,
    );
    final chevron = find.descendant(
      of: entry,
      matching: find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.size == const Size(8, 14),
      ),
    );
    expect(tester.getSize(chevron), const Size(8, 14));
    expect(tester.getTopRight(entry).dx - tester.getTopRight(chevron).dx, 18);
  });
}
