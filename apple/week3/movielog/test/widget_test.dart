import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/main.dart';
import 'package:movielog/router/app_router.dart';

void main() {
  // AppRouter.router는 static이라 테스트마다 시작 화면으로 되돌림
  setUp(() => AppRouter.router.go('/start'));

  testWidgets('시작 화면에서 회원가입 화면으로 이동한다', (WidgetTester tester) async {
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();

    expect(find.text('MovieLog'), findsOneWidget);

    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();

    expect(find.text('환영합니다!\n간단한 정보만 입력하고 시작해보세요.'), findsOneWidget);
    expect(find.text('가입하기'), findsOneWidget);
  });

  testWidgets('시작하기 후 하단 탭으로 홈/영화/마이를 이동한다', (WidgetTester tester) async {
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('오늘은 어떤\n영화를 볼까요?'), findsOneWidget);

    await tester.tap(find.text('영화'));
    await tester.pumpAndSettle();
    expect(find.text('별빛 아래 우리'), findsOneWidget);
    expect(find.text('우주의 끝에서'), findsOneWidget);

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    expect(find.text('무비러버'), findsOneWidget);
  });

  testWidgets('하단 네비게이션이 Figma 크기를 따른다', (WidgetTester tester) async {
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('시작하기'));
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
    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('시작하기'));
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

    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('시작하기'));
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

    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('시작하기'));
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

  testWidgets('전체보기를 누르면 영화 탭으로 이동한다', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(388, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('시작하기'));
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

      await tester.pumpWidget(const MovieLogApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('영화'));
      await tester.pumpAndSettle();
    }

    Finder itemOf(String title) => find.ancestor(
      of: find.text(title),
      matching: find.byWidgetPredicate(
        (widget) => widget is Column && widget.children.length == 3,
      ),
    );

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

      await tester.pumpWidget(const MovieLogApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('시작하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('영화'));
      await tester.pumpAndSettle();
      // 영화 목록에서 첫 번째 카드를 눌러 상세로 이동
      await tester.tap(find.text('별빛 아래 우리'));
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

    testWidgets('뒤로가기를 누르면 영화 목록으로 돌아간다', (WidgetTester tester) async {
      await openDetail(tester);

      await tester.tap(find.byTooltip('뒤로가기'));
      await tester.pumpAndSettle();
      expect(find.text('Cinema Archive'), findsNothing);
      expect(find.text('우주의 끝에서'), findsOneWidget);
    });

    testWidgets('즐겨찾기를 누르면 상태가 바뀌고 안내 메시지가 뜬다', (WidgetTester tester) async {
      await openDetail(tester);

      await tester.tap(find.text('즐겨찾기'));
      await tester.pump();
      expect(find.text('즐겨찾기에 추가했습니다.'), findsOneWidget);
      // 즐겨찾기 상태에서는 제공된 북마크 아이콘(PNG)을 사용
      Finder bookmarkPng() => find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/icons/bookmark_filled.png',
      );
      expect(bookmarkPng(), findsOneWidget);
      final toggle = tester.getSemantics(
        find
            .ancestor(of: find.text('즐겨찾기'), matching: find.byType(Semantics))
            .first,
      );
      expect(toggle.flagsCollection.isToggled, isNotNull);

      await tester.tap(find.text('즐겨찾기'));
      await tester.pump();
      expect(find.text('즐겨찾기를 해제했습니다.'), findsOneWidget);
      expect(bookmarkPng(), findsNothing);
    });

    testWidgets('평점 남기기를 누르면 별점 Dialog가 뜨고 결과를 안내한다', (
      WidgetTester tester,
    ) async {
      await openDetail(tester);

      await tester.tap(find.text('평점 남기기'));
      await tester.pumpAndSettle();
      expect(find.text('영화는 어떠셨나요?'), findsOneWidget);

      // 다섯 번째 별의 오른쪽 끝 → 5점
      final dialogStar = find
          .descendant(
            of: find.byType(Dialog),
            matching: find.byType(SvgPicture),
          )
          .last;
      final rect = tester.getRect(dialogStar);
      await tester.tapAt(rect.centerRight - const Offset(2, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(find.text('평점 5.0점을 남겼습니다.'), findsOneWidget);
    });
  });

  testWidgets('홈 배너 상세보기를 누르면 영화 상세로 이동한다', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('상세보기'));
    await tester.pumpAndSettle();
    expect(find.text('Cinema Archive'), findsOneWidget);
    expect(find.text('(1,245)'), findsOneWidget);
  });

  testWidgets('마이 탭에 1주차 프로필 화면이 나온다', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MovieLogApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();

    // 헤더와 내용
    expect(find.text('내 프로필'), findsOneWidget);
    expect(find.byTooltip('내 정보'), findsOneWidget);
    expect(find.text('무비러버'), findsOneWidget);
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
  });
}
