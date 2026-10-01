import 'package:flutter/material.dart';
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
    expect(find.text('마이 화면'), findsOneWidget);
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
    expect(tester.getTopLeft(banner) - tester.getTopLeft(greeting), const Offset(0, 72 + 16));

    // 상세보기 버튼 308 x 48, 배너 하단에서 24 위
    final button = find.ancestor(of: find.text('상세보기'), matching: find.byType(InkWell));
    expect(tester.getSize(button), const Size(308, 48));
    expect(tester.getBottomLeft(banner).dy - tester.getBottomLeft(button).dy, 24);

    // 추천 신작 칩 높이 34 (너비는 글꼴에 따라 달라짐)
    final chip = find.ancestor(of: find.text('추천 신작'), matching: find.byType(BackdropFilter));
    expect(tester.getSize(chip).height, 34);

    // 배너 하단 영역 218 = 칩부터 버튼까지 + padding 24 x 2
    expect(tester.getBottomLeft(banner).dy - tester.getTopLeft(chip).dy, 218 - 24);
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
    final poster = find.ancestor(of: find.text('1'), matching: find.byType(ClipRRect)).last;
    expect(tester.getSize(poster), const Size(140, 200));
    final rankChip = find.ancestor(of: find.text('1'), matching: find.byType(BackdropFilter));
    expect(tester.getTopLeft(rankChip) - tester.getTopLeft(poster), const Offset(8, 8));
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
}
