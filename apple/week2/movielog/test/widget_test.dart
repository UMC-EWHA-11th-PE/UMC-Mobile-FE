import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/main.dart';

void main() {
  testWidgets('회원가입 화면이 렌더링되고 버튼은 처음에 비활성이다', (tester) async {
    await tester.pumpWidget(const MovieLogApp());

    expect(find.text('회원가입'), findsOneWidget);
    expect(find.text('닉네임을 입력해주세요'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '가입하기'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('닉네임이 2자 미만이면 오류 문구를 보여준다', (tester) async {
    await tester.pumpWidget(const MovieLogApp());

    await tester.enterText(find.byType(TextFormField).first, 'a');
    await tester.pump();

    expect(find.text('닉네임은 2자 이상이어야 합니다.'), findsOneWidget);
  });

  testWidgets('모든 값이 유효하고 약관에 동의하면 버튼이 활성화된다', (tester) async {
    await tester.pumpWidget(const MovieLogApp());

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '무비러버');
    await tester.enterText(fields.at(1), 'movie@example.com');
    await tester.enterText(fields.at(2), 'password123');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '가입하기'),
    );
    expect(button.onPressed, isNotNull);
  });
}
