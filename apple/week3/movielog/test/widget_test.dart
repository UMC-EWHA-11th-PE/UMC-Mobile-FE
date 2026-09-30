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

    await tester.tap(find.byIcon(Icons.movie_outlined));
    await tester.pumpAndSettle();
    expect(find.text('별빛 아래 우리'), findsOneWidget);
    expect(find.text('우주의 끝에서'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('마이 화면'), findsOneWidget);
  });
}
