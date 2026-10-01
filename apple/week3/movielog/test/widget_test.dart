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
    expect(find.text('홈 화면'), findsOneWidget);

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
}
