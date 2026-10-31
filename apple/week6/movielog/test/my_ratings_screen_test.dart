import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';

import 'fake_ratings.dart';
import 'fake_tmdb.dart';

/// 라우터와 같은 방식으로 ViewModel을 만들어 붙입니다.
Widget _app(RatingApiService service) => MaterialApp(
  theme: AppTheme.light,
  home: ChangeNotifierProvider<MyRatingsViewModel>(
    create: (_) =>
        MyRatingsViewModel(service, fakeTmdbService(), sampleMemberId)..load(),
    child: const MyRatingsScreen(),
  ),
);

void main() {
  testWidgets('Loading → Success: 영화 제목·별점·한줄평·등록일을 보여준다', (tester) async {
    final gate = Completer<void>();
    await tester.pumpWidget(
      _app(
        fakeRatingApiService(
          ratings: [
            fakeRatingJson(ratingId: 2, movieId: 1, score: 4),
            fakeRatingJson(ratingId: 1, movieId: 7, comment: null),
          ],
          gate: gate.future,
        ),
      ),
    );

    expect(find.text('내가 등록한 평점'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('학습용 memberId 1의 샘플 평점입니다.'), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsOneWidget);
    expect(find.text('마션 레스큐'), findsOneWidget);
    expect(find.text('4.0'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);
    expect(find.text('2026.09.06'), findsNWidgets(2));
    // comment가 null인 평점은 한줄평을 그리지 않음
    expect(find.text('최고의 영화!'), findsOneWidget);
  });

  testWidgets('Empty: 평점이 없으면 안내 문구', (tester) async {
    await tester.pumpWidget(_app(fakeRatingApiService()));
    await tester.pumpAndSettle();

    expect(find.text('아직 등록된 평점이 없습니다.'), findsOneWidget);
    expect(find.text('학습용 memberId 1의 샘플 평점입니다.'), findsOneWidget);
  });

  testWidgets('Error: 404 안내와 다시 시도', (tester) async {
    await tester.pumpWidget(_app(fakeRatingApiService(statusCode: 404)));
    await tester.pumpAndSettle();

    expect(find.text('존재하지 않는 회원입니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('다시 시도를 누르면 다시 불러온다', (tester) async {
    final requests = <String>[];
    await tester.pumpWidget(
      _app(fakeRatingApiService(fail: true, requests: requests)),
    );
    await tester.pumpAndSettle();
    expect(find.text('평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(requests, hasLength(2));
  });

  testWidgets('TMDB에서 못 찾은 영화는 placeholder와 movieId로 평점을 남긴다', (tester) async {
    await tester.pumpWidget(
      _app(fakeRatingApiService(ratings: [fakeRatingJson(movieId: 999999)])),
    );
    await tester.pumpAndSettle();

    expect(find.text('영화 정보를 찾을 수 없어요'), findsOneWidget);
    expect(find.text('movieId 999999'), findsOneWidget);
    expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    expect(find.text('일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.'), findsOneWidget);
    expect(find.text('최고의 영화!'), findsOneWidget);
  });
}
