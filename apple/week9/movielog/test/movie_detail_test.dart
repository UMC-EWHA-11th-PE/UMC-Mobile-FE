import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/data/models/member_info.dart';
import 'package:movielog/data/models/rating_dto.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/movie_detail_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/widgets/favorite_button.dart';
import 'package:movielog/widgets/rating_dialog.dart';

import 'fake_ratings.dart';
import 'fake_auth.dart';
import 'fake_favorites.dart';
import 'fake_tmdb.dart';

/// 라우터와 같은 방식으로 상세 ViewModel을 만들어 붙입니다.
/// 등록 성공 평점은 [created]에, 세션 만료 요청은 [expired]에 기록합니다.
Widget _app(
  TmdbMovieService service,
  int? movieId, {
  RatingApiService? ratingService,
  List<RatingDto>? created,
  List<bool>? expired,
  FakeFavoriteServer? favorites,
  SessionGuard? guard,
}) => MaterialApp(
  theme: AppTheme.light,
  home: ChangeNotifierProvider<MovieDetailViewModel>(
    create: (_) => MovieDetailViewModel(
      service,
      movieId: movieId,
      ratingService: ratingService ?? fakeRatingApiService(),
      onRatingCreated: created?.add,
      onSessionExpired: () async => expired?.add(true),
    )..load(),
    child: ChangeNotifierProvider<FavoriteDetailViewModel>(
      create: (_) => FavoriteDetailViewModel(
        (favorites ?? FakeFavoriteServer()).service,
        movieId: movieId,
        guard: guard ?? (SessionGuard()..startSession('mingo@example.com')),
        onSessionExpired: () async => expired?.add(true),
      )..load(),
      child: MovieDetailScreen(movieId: movieId),
    ),
  ),
);

/// 평점 Dialog에서 [stars]점을 골라 [comment]와 함께 확인을 누릅니다.
Future<void> _rate(WidgetTester tester, int stars, {String? comment}) async {
  await tester.tap(find.text('평점 남기기'));
  await tester.pumpAndSettle();
  await tester.tap(
    find
        .descendant(of: find.byType(Dialog), matching: find.byType(SvgPicture))
        .at(stars - 1),
  );
  await tester.pump(); // 별점이 반영돼 확인 버튼이 켜진 프레임을 그립니다.
  if (comment != null) {
    await tester.enterText(find.byType(TextField), comment);
  }
  await tester.tap(find.text('확인'));
  await tester.pumpAndSettle();
}

void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('TMDB 영화 상세', () {
    testWidgets('불러오는 동안 로딩을 보여주고, 완료되면 TMDB 상세를 보여준다', (tester) async {
      _useTallView(tester);
      final requests = <Uri>[];
      await tester.pumpWidget(
        _app(
          fakeTmdbService(
            requests: requests,
            delay: const Duration(milliseconds: 100),
          ),
          1,
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(requests.single.path, endsWith('/movie/1'));
      expect(find.text('별빛 아래 우리'), findsOneWidget);
      expect(find.text('2024 • 로맨스/드라마 • 124분'), findsOneWidget);
      // TMDB 평점 9.0(10점 만점) → 4.5(5점 만점), vote_count → 참여 수
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('(1,245)'), findsOneWidget);
      // 포스터가 없으면 placeholder
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });

    testWidgets('줄거리가 없으면 안내 문구를 보여준다', (tester) async {
      _useTallView(tester);
      // id 2(우주의 끝에서)는 Mock 시놉시스가 없어 overview가 빈 문자열
      await tester.pumpWidget(_app(fakeTmdbService(), 2));
      await tester.pumpAndSettle();

      expect(find.text('우주의 끝에서'), findsOneWidget);
      expect(find.text('줄거리 정보가 없어요.'), findsOneWidget);
    });

    testWidgets('없는 영화면 찾을 수 없다고 안내한다', (tester) async {
      await tester.pumpWidget(_app(fakeTmdbService(), 999));
      await tester.pumpAndSettle();

      expect(find.text('영화를 찾을 수 없습니다.'), findsOneWidget);
    });

    testWidgets('실패하면 다시 시도할 수 있다', (tester) async {
      _useTallView(tester);
      var failing = true;
      await tester.pumpWidget(_app(fakeTmdbService(fail: () => failing), 1));
      await tester.pumpAndSettle();
      expect(find.text('영화 정보를 불러오지 못했어요.'), findsOneWidget);

      failing = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('별빛 아래 우리'), findsOneWidget);
    });
  });

  group('평점 등록 (POST /v8/ratings)', () {
    testWidgets(
      'memberId 없이 TMDB id로 등록하고, 응답 평점을 세션에 넘긴 뒤 Dialog를 닫고 Snackbar',
      (tester) async {
        _useTallView(tester);
        final server = FakeRatingServer();
        final created = <RatingDto>[];
        await tester.pumpWidget(
          _app(
            fakeTmdbService(),
            1,
            ratingService: server.service,
            created: created,
          ),
        );
        await tester.pumpAndSettle();

        await _rate(tester, 5);

        expect(server.calls, ['POST /v8/ratings']);
        // 코멘트를 비우면 comment 키를 보내지 않고, memberId도 보내지 않습니다.
        expect(server.bodies.single, {'movieId': 1, 'score': 5});
        expect(created.single.movieId, 1);
        expect(created.single.score, 5);
        expect(find.byType(RatingDialog), findsNothing);
        expect(find.textContaining('평점을 등록했습니다.'), findsOneWidget);
      },
    );

    testWidgets('세션 만료(AUTH401_4)면 세션 정리를 요청하고 등록 성공으로 처리하지 않는다', (
      tester,
    ) async {
      _useTallView(tester);
      final server = FakeRatingServer()
        ..writeError = (
          status: 401,
          code: 'AUTH401_4',
          message: '토큰이 만료되었습니다. 다시 로그인해주세요.',
        );
      final expired = <bool>[];
      final created = <RatingDto>[];
      await tester.pumpWidget(
        _app(
          fakeTmdbService(),
          1,
          ratingService: server.service,
          created: created,
          expired: expired,
        ),
      );
      await tester.pumpAndSettle();

      await _rate(tester, 4);

      expect(expired, [true]);
      expect(created, isEmpty);
      expect(find.textContaining('평점을 등록했습니다.'), findsNothing);
    });

    testWidgets('RATING409_1 중복 등록이면 Dialog에 기존 기록 확인 안내를 보여주고 입력을 유지한다', (
      tester,
    ) async {
      _useTallView(tester);
      final server = FakeRatingServer()
        ..writeError = (
          status: 409,
          code: 'RATING409_1',
          message: '이미 이 영화에 평점을 남기셨습니다.',
        );
      await tester.pumpWidget(
        _app(fakeTmdbService(), 1, ratingService: server.service),
      );
      await tester.pumpAndSettle();

      await _rate(tester, 3, comment: '두 번째 감상');

      expect(find.byType(RatingDialog), findsOneWidget);
      // 실패 문구는 Dialog 안과 Snackbar에 함께 보입니다.
      expect(
        find.descendant(
          of: find.byType(RatingDialog),
          matching: find.text('이미 평점을 남긴 영화예요. 내가 등록한 평점에서 확인해 주세요.'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('이미 평점을 남긴 영화예요. 내가 등록한 평점에서 확인해 주세요.'),
        ),
        findsOneWidget,
      );
      expect(find.text('두 번째 감상'), findsOneWidget);
      expect(find.textContaining('평점을 등록했습니다.'), findsNothing);
      // 409는 목록을 다시 조회할 필요가 없는 오류 — GET 없음
      expect(server.calls, ['POST /v8/ratings']);
    });
  });

  testWidgets('영화 목록 카드를 누르면 TMDB id로 상세를 요청한다', (tester) async {
    _useTallView(tester);
    final requests = <Uri>[];
    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: FakeFavoriteServer().service,
        authViewModel: await signedInAuth(),
        tmdbMovieService: fakeTmdbService(requests: requests),
      ),
    );
    await tester.pumpAndSettle();
    appRouter(tester).go('/movies');
    await tester.pumpAndSettle();

    await tester.tap(find.text('우주의 끝에서'));
    await tester.pumpAndSettle();

    expect(
      appRouter(tester)
          .routerDelegate
          .currentConfiguration
          .last
          .matchedLocation,
      '/movies/2',
    );
    expect(requests.last.path, endsWith('/movie/2'));
    expect(find.text('Cinema Archive'), findsOneWidget);
  });

  testWidgets('목록에서 넘긴 TmdbMovieDto(extra)로 로딩 없이 먼저 보여주고, 상세 응답으로 채운다', (
    tester,
  ) async {
    _useTallView(tester);
    final requests = <Uri>[];
    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: FakeFavoriteServer().service,
        authViewModel: await signedInAuth(),
        tmdbMovieService: fakeTmdbService(
          requests: requests,
          delay: const Duration(milliseconds: 100),
        ),
      ),
    );
    await tester.pumpAndSettle();
    appRouter(tester).go('/movies');
    await tester.pumpAndSettle();

    await tester.tap(find.text('별빛 아래 우리'));
    await tester.pump(); // 화면 전환 시작
    await tester.pump(const Duration(milliseconds: 50)); // 상세 응답 전
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('별빛 아래 우리'), findsWidgets);

    await tester.pumpAndSettle();
    expect(requests.last.path, endsWith('/movie/1'));
    // 상세 응답의 러닝타임·장르로 채워짐
    expect(find.text('2024 • 로맨스/드라마 • 124분'), findsOneWidget);
  });

  group('즐겨찾기 버튼 (v8)', () {
    Finder filledBookmark() => find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName ==
              'assets/icons/bookmark_filled.png',
    );

    testWidgets('등록 전 → 요청 중 로딩 → 등록 후, Snackbar', (tester) async {
      _useTallView(tester);
      final favorites = FakeFavoriteServer();
      await tester.pumpWidget(_app(fakeTmdbService(), 1, favorites: favorites));
      await tester.pumpAndSettle();
      expect(filledBookmark(), findsNothing);

      final gate = Completer<void>();
      favorites.gate = gate.future;
      await tester.tap(find.text('즐겨찾기'));
      await tester.pump();
      // 요청 중: 버튼 안에 로딩
      expect(
        find.descendant(
          of: find.byType(FavoriteButton),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );

      gate.complete();
      favorites.gate = null;
      await tester.pumpAndSettle();
      expect(filledBookmark(), findsOneWidget);
      expect(find.text('즐겨찾기에 추가했습니다.'), findsOneWidget);
      expect(favorites.movieIds, [1]);
    });

    testWidgets('이미 즐겨찾기한 영화는 채워진 북마크로 시작하고 해제할 수 있다', (tester) async {
      _useTallView(tester);
      final favorites = FakeFavoriteServer(movieIds: [1]);
      await tester.pumpWidget(_app(fakeTmdbService(), 1, favorites: favorites));
      await tester.pumpAndSettle();
      expect(filledBookmark(), findsOneWidget);

      await tester.tap(find.text('즐겨찾기'));
      await tester.pumpAndSettle();
      expect(filledBookmark(), findsNothing);
      expect(find.text('즐겨찾기를 해제했습니다.'), findsOneWidget);
    });

    testWidgets('실패하면 이전 상태를 유지하고 하단에 안내를 보여준다', (tester) async {
      _useTallView(tester);
      final favorites = FakeFavoriteServer()..failMethods.add('POST');
      await tester.pumpWidget(_app(fakeTmdbService(), 1, favorites: favorites));
      await tester.pumpAndSettle();

      await tester.tap(find.text('즐겨찾기'));
      await tester.pumpAndSettle();
      expect(filledBookmark(), findsNothing);
      expect(find.text('저장하지 못했습니다. 다시 시도해 주세요.'), findsOneWidget);
      expect(find.text('즐겨찾기에 추가했습니다.'), findsNothing);

      // 다시 시도해 성공하면 안내가 사라집니다.
      favorites.failMethods.clear();
      await tester.tap(find.text('즐겨찾기'));
      await tester.pumpAndSettle();
      expect(find.text('저장하지 못했습니다. 다시 시도해 주세요.'), findsNothing);
      expect(filledBookmark(), findsOneWidget);
    });
  });

  testWidgets('앱 Route — 로그인한 계정의 즐겨찾기 여부로 상세 버튼이 시작하고, 다른 계정으로 바꾸면 새로 확인한다', (
    tester,
  ) async {
    _useTallView(tester);
    final favorites = FakeFavoriteServer(movieIds: [1]);
    final memberApi = FakeMemberApiService();
    final auth = await signedInAuth(memberApi: memberApi);
    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: favorites.service,
        authViewModel: auth,
        tmdbMovieService: fakeTmdbService(),
      ),
    );
    await tester.pumpAndSettle();
    appRouter(tester).push('/movies/1');
    await tester.pumpAndSettle();

    Finder filled() => find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName ==
              'assets/icons/bookmark_filled.png',
    );
    expect(filled(), findsOneWidget);
    expect(favorites.calls, ['GET /v8/favorites/1']);

    // 다른 계정으로 다시 로그인 — 서버의 즐겨찾기도 그 계정 기준으로 바뀐다고 가정
    await auth.logout();
    await tester.pumpAndSettle();
    favorites.movieIds.clear();
    memberApi.member = MemberInfo(
      email: 'other@example.com',
      nickname: '다른 계정',
      createdAt: DateTime.utc(2026, 9, 6),
    );
    await auth.login('other@example.com', 'password1!');
    await tester.pumpAndSettle();
    appRouter(tester).push('/movies/1');
    await tester.pumpAndSettle();

    expect(filled(), findsNothing);
    expect(favorites.calls.last, 'GET /v8/favorites/1');
  });
}
