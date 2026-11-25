import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/favorites_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/favorites_view_model.dart';

import 'fake_auth.dart';
import 'fake_favorites.dart';
import 'fake_tmdb.dart';

/// movieId로 TMDB 영화 한 편을 돌려주는 가짜 — 실패할 id·동시 요청 수를 확인합니다.
class FakeMovieLookup extends TmdbMovieService {
  FakeMovieLookup({this.failing = const {}, this.delay = Duration.zero})
    : super(Dio());

  /// 이 id는 연결 실패 — 테스트 도중 바꿔 재시도 성공을 만들 수 있습니다.
  Set<int> failing;
  final Duration delay;
  final requested = <int>[];
  int _running = 0;
  int maxRunning = 0;

  @override
  Future<TmdbMovieDto> fetchMovie(int movieId) async {
    requested.add(movieId);
    _running++;
    if (_running > maxRunning) maxRunning = _running;
    try {
      await Future<void>.delayed(delay);
      if (failing.contains(movieId)) {
        throw DioException.connectionError(
          requestOptions: RequestOptions(path: '/movie/$movieId'),
          reason: '테스트용 연결 실패',
        );
      }
      return TmdbMovieDto(
        id: movieId,
        title: '영화 제목 $movieId',
        overview: '',
        posterPath: null,
        backdropPath: null,
        releaseDate: null,
        genreIds: const [],
        voteAverage: 0,
        popularity: 0,
      );
    } finally {
      _running--;
    }
  }
}

SessionGuard _guard([String email = 'mingo@example.com']) =>
    SessionGuard()..startSession(email);

Widget _screen(FavoritesViewModel viewModel) => MaterialApp(
  theme: AppTheme.light,
  home: ChangeNotifierProvider<FavoritesViewModel>.value(
    value: viewModel,
    child: const FavoritesScreen(),
  ),
);

void main() {
  group('FavoritesViewModel', () {
    test('즐겨찾기 movieId로 TMDB 정보를 가져와 같은 순서로 합친다', () async {
      final server = FakeFavoriteServer(movieIds: [550, 13, 99]);
      final tmdb = FakeMovieLookup();
      final viewModel = FavoritesViewModel(
        server.service,
        tmdb,
        guard: _guard(),
      );

      await viewModel.load();

      expect(viewModel.phase, LoadPhase.ready);
      expect(viewModel.items.map((i) => i.movie?.title), [
        '영화 제목 550',
        '영화 제목 13',
        '영화 제목 99',
      ]);
      expect(server.calls, ['GET /v8/favorites']); // memberId 없이 JWT 목록
    });

    test('즐겨찾기가 많아도 TMDB 요청은 한 번에 최대 5개', () async {
      final ids = List.generate(23, (i) => i + 1);
      final tmdb = FakeMovieLookup(delay: const Duration(milliseconds: 5));
      final viewModel = FavoritesViewModel(
        FakeFavoriteServer(movieIds: ids).service,
        tmdb,
        guard: _guard(),
      );

      await viewModel.load();

      expect(tmdb.requested.toSet(), ids.toSet());
      expect(tmdb.maxRunning, 5);
      expect(viewModel.items.every((i) => i.movie != null), isTrue);
    });

    test('한 영화가 실패해도 나머지는 보여주고, 그 카드만 다시 조회한다', () async {
      final tmdb = FakeMovieLookup(failing: {13});
      final viewModel = FavoritesViewModel(
        FakeFavoriteServer(movieIds: [550, 13]).service,
        tmdb,
        guard: _guard(),
      );
      await viewModel.load();

      expect(viewModel.phase, LoadPhase.ready);
      expect(viewModel.items[0].movie?.title, '영화 제목 550');
      expect(viewModel.items[1].movieFailed, isTrue);

      tmdb.failing = {};
      tmdb.requested.clear();
      await viewModel.retryMovie(13);
      expect(tmdb.requested, [13]); // 성공한 550은 다시 요청하지 않음
      expect(viewModel.items[1].movie?.title, '영화 제목 13');
      expect(viewModel.items[1].movieFailed, isFalse);
    });

    test('즐겨찾기가 없으면 empty, 목록 조회 실패면 error', () async {
      final server = FakeFavoriteServer();
      final viewModel = FavoritesViewModel(
        server.service,
        FakeMovieLookup(),
        guard: _guard(),
      );
      await viewModel.load();
      expect(viewModel.phase, LoadPhase.empty);

      server.failMethods.add('GET');
      await viewModel.load();
      expect(viewModel.phase, LoadPhase.error);
      expect(viewModel.message, '즐겨찾기를 불러오지 못했습니다.');
    });

    test('MEMBER404_1은 회원 없음으로 안내하고 세션을 정리하지 않는다', () async {
      final server = FakeFavoriteServer()
        ..nextError = (status: 404, code: 'MEMBER404_1');
      final expired = <bool>[];
      final viewModel = FavoritesViewModel(
        server.service,
        FakeMovieLookup(),
        guard: _guard(),
        onSessionExpired: () async => expired.add(true),
      );
      await viewModel.load();

      expect(viewModel.phase, LoadPhase.error);
      expect(viewModel.message, '회원 정보를 찾을 수 없습니다.');
      expect(expired, isEmpty);
    });

    test('현재 세션의 401만 세션 만료를 요청한다', () async {
      final server = FakeFavoriteServer()
        ..nextError = (status: 401, code: 'AUTH401_3');
      final expired = <bool>[];
      final viewModel = FavoritesViewModel(
        server.service,
        FakeMovieLookup(),
        guard: _guard(),
        onSessionExpired: () async => expired.add(true),
      );
      await viewModel.load();
      expect(expired, [true]);

      // 응답 도중 계정이 바뀌면 늦게 온 401은 무시
      final guard = _guard('a@example.com');
      final gate = Completer<void>();
      final late = FakeFavoriteServer()
        ..gate = gate.future
        ..nextError = (status: 401, code: 'AUTH401_3');
      final stale = FavoritesViewModel(
        late.service,
        FakeMovieLookup(),
        guard: guard,
        onSessionExpired: () async => expired.add(true),
      );
      final loading = stale.load();
      guard.startSession('b@example.com');
      gate.complete();
      await loading;
      expect(expired, [true]);
    });

    test('로그아웃 뒤 늦게 도착한 목록은 반영하지 않는다', () async {
      final guard = _guard();
      final gate = Completer<void>();
      final server = FakeFavoriteServer(movieIds: [550])..gate = gate.future;
      final viewModel = FavoritesViewModel(
        server.service,
        FakeMovieLookup(),
        guard: guard,
      );
      final loading = viewModel.load();

      guard.invalidate();
      gate.complete();
      await loading;
      expect(viewModel.items, isEmpty);
    });
  });

  group('FavoritesScreen', () {
    testWidgets('빈 결과 안내', (tester) async {
      final viewModel = FavoritesViewModel(
        FakeFavoriteServer().service,
        FakeMovieLookup(),
        guard: _guard(),
      )..load();
      await tester.pumpWidget(_screen(viewModel));
      await tester.pumpAndSettle();

      expect(find.text('내 즐겨찾기'), findsOneWidget);
      expect(find.text('아직 즐겨찾기한 영화가 없습니다.'), findsOneWidget);
      expect(find.text('영화 상세에서 북마크를 눌러보세요.'), findsOneWidget);
    });

    testWidgets('조회 오류 → 다시 시도로 목록', (tester) async {
      final server = FakeFavoriteServer(movieIds: [550])
        ..failMethods.add('GET');
      final viewModel = FavoritesViewModel(
        server.service,
        FakeMovieLookup(),
        guard: _guard(),
      )..load();
      await tester.pumpWidget(_screen(viewModel));
      await tester.pumpAndSettle();
      expect(find.text('즐겨찾기를 불러오지 못했습니다.'), findsOneWidget);

      server.failMethods.clear();
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('영화 제목 550'), findsOneWidget);
    });

    testWidgets('영화 정보 부분 실패 — 그 카드만 placeholder와 정보 다시 불러오기', (tester) async {
      final tmdb = FakeMovieLookup(failing: {13});
      final viewModel = FavoritesViewModel(
        FakeFavoriteServer(movieIds: [550, 13]).service,
        tmdb,
        guard: _guard(),
      )..load();
      await tester.pumpWidget(_screen(viewModel));
      await tester.pumpAndSettle();

      expect(find.text('영화 제목 550'), findsOneWidget);
      expect(find.text('영화 #13'), findsOneWidget);
      expect(find.text('정보 다시 불러오기'), findsOneWidget);
      expect(find.text('즐겨찾기한 영화'), findsNWidgets(2));

      tmdb.failing = {};
      await tester.tap(find.text('정보 다시 불러오기'));
      await tester.pumpAndSettle();
      expect(find.text('영화 제목 13'), findsOneWidget);
      expect(find.text('정보 다시 불러오기'), findsNothing);
    });
  });

  testWidgets('마이 → 내 즐겨찾기는 하단 탭 없이 열리고 카드로 상세에 간다', (tester) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final favorites = FakeFavoriteServer(movieIds: [1]);

    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: favorites.service,
        authViewModel: await signedInAuth(),
        tmdbMovieService: fakeTmdbService(),
      ),
    );
    await tester.pumpAndSettle();
    appRouter(tester).go('/my');
    await tester.pumpAndSettle();

    await tester.tap(find.text('내 즐겨찾기'));
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesScreen), findsOneWidget);
    expect(find.text('마이'), findsNothing); // 하단 NavigationBar 없음
    expect(find.text('별빛 아래 우리'), findsOneWidget);

    // 상세에서 해제하고 돌아오면 목록이 다시 맞춰진다
    await tester.tap(find.text('별빛 아래 우리'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('즐겨찾기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(find.text('아직 즐겨찾기한 영화가 없습니다.'), findsOneWidget);
  });
}
