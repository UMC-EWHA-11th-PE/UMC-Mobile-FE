import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/widgets/genre_filter_sheet.dart';
import 'package:movielog/widgets/movie_rating_indicator.dart';
import 'package:movielog/widgets/rating_dialog.dart';

/// 버튼을 누르면 [onPressed]를 실행하는 테스트용 화면
Widget _launcher(Future<void> Function(BuildContext context) onPressed) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => onPressed(context),
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('MovieRatingIndicator는 별점 숫자를 소수 첫째 자리까지 표시한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MovieRatingIndicator(rating: 4.3)),
    );

    expect(find.text('4.3'), findsOneWidget);
  });

  testWidgets('RatingDialog는 선택한 별점을 반환한다', (tester) async {
    double? result;
    await tester.pumpWidget(_launcher((context) async {
      result = await showDialog<double>(
        context: context,
        builder: (context) => const RatingDialog(),
      );
    }));

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('영화는 어떠셨나요?'), findsOneWidget);

    // 다섯 번째 별의 오른쪽 끝을 눌러 5점 선택 (가운데를 누르면 반 칸인 4.5)
    final lastStar = tester.getRect(find.byIcon(Icons.star).last);
    await tester.tapAt(lastStar.centerRight - const Offset(2, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(result, 5.0);
  });

  testWidgets('GenreFilterSheet는 체크한 장르를 반환한다', (tester) async {
    Set<String>? result;
    await tester.pumpWidget(_launcher((context) async {
      result = await GenreFilterSheet.show(context, selected: {'드라마'});
    }));

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('액션'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(result, {'드라마', '액션'});
  });
}
