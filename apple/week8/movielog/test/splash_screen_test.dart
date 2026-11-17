import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/screens/splash_screen.dart';
import 'package:movielog/theme/app_theme.dart';

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void main() {
  testWidgets('세션 확인 중에는 인디케이터만 보이고 다시 시도 버튼은 없다', (tester) async {
    await tester.pumpWidget(_wrap(const SplashScreen()));

    expect(find.text('FLUTTER 8주차'), findsOneWidget);
    expect(find.text('영화의 순간을\n기록하세요'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('다시 시도'), findsNothing);
  });

  testWidgets('확인 실패 시 안내 문구와 다시 시도 버튼을 보여주고 누르면 콜백을 호출한다', (tester) async {
    var retried = 0;
    await tester.pumpWidget(_wrap(SplashScreen(onRetry: () => retried++)));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('로그인 상태를 확인하지 못했어요.'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    expect(retried, 1);
  });

  testWidgets('message를 넘기면 기본 문구 대신 보여준다', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SplashScreen(message: '인증 저장소를 읽지 못했어요. 다시 시도해 주세요.', onRetry: () {}),
      ),
    );

    expect(find.text('인증 저장소를 읽지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('로그인 상태를 확인하지 못했어요.'), findsNothing);
  });

  testWidgets('확인 중(인디케이터만 있을 때)에도 로고·문구가 화면 가운데에 온다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final screen in [SplashScreen(onRetry: () {}), const SplashScreen()]) {
      await tester.pumpWidget(_wrap(screen));
      for (final text in ['FLUTTER 8주차', '영화의 순간을\n기록하세요']) {
        expect(tester.getCenter(find.text(text)).dx, 390 / 2);
      }
      expect(tester.getCenter(find.byType(SvgPicture)).dx, 390 / 2);
    }
  });
}
