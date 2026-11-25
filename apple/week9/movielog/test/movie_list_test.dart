import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:movielog/data/local/genre_preference.dart';
import 'package:movielog/data/local/secure_storage_cleanup.dart';
import 'package:movielog/data/services/fake_movie_service.dart';
import 'package:dio/dio.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/widgets/movie_page_footer.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';

import 'fake_tmdb.dart';

/// 라우터와 같은 방식으로 화면마다 ViewModel을 만들어 붙입니다.
Widget _app(TmdbMovieService service, {Key? key}) => MaterialApp(
  theme: AppTheme.light,
  home: ChangeNotifierProvider<PagedMoviesViewModel>(
    key: key,
    create: (_) => PagedMoviesViewModel(service)..start(),
    child: const MovieListScreen(),
  ),
);

/// Discover 요청의 with_genres 값 (없으면 null)
List<String?> _discoverGenres(List<Uri> requests) => [
  for (final uri in requests)
    if (uri.path.endsWith('/discover/movie'))
      uri.queryParameters['with_genres'],
];

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('FakeMovieService', () {
    const service = FakeMovieService();

    test('mode에 따라 영화 목록·빈 목록·예외를 돌려준다', () async {
      expect(await service.fetchMovies(), isNotEmpty);
      expect(await service.fetchMovies(mode: MovieLoadMode.empty), isEmpty);
      expect(
        service.fetchMovies(mode: MovieLoadMode.failure),
        throwsA(isA<MovieLoadException>()),
      );
    });
  });

  group('영화 목록 상태', () {
    testWidgets('불러오는 동안 로딩을 보여주고, 완료되면 영화와 장르 칩을 보여준다', (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(fakeTmdbService(delay: const Duration(milliseconds: 100))),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('별빛 아래 우리'), findsOneWidget);
      // 장르 칩은 Genre API 결과 — 맨 앞은 전체
      expect(find.text('전체'), findsOneWidget);
      expect(find.text('드라마'), findsOneWidget);
    });

    testWidgets('포스터가 없는 영화는 placeholder를 보여준다', (tester) async {
      await tester.pumpWidget(_app(fakeTmdbService()));
      await tester.pumpAndSettle();

      expect(
        find.byIcon(Icons.image_not_supported_outlined),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('빈 목록이면 안내 문구를 보여준다', (tester) async {
      await tester.pumpWidget(_app(fakeTmdbService(results: const [])));
      await tester.pumpAndSettle();

      expect(find.text('조건에 맞는 영화가 없습니다.'), findsOneWidget);
    });

    testWidgets('실패하면 안내 문구와 다시 시도 버튼을 보여주고, 누르면 다시 불러온다', (tester) async {
      var failing = true;
      await tester.pumpWidget(
        _app(
          fakeTmdbService(
            fail: () => failing,
            delay: const Duration(milliseconds: 100),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('영화 목록을 불러오지 못했습니다.'), findsOneWidget);

      failing = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('다시 시도'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('별빛 아래 우리'), findsOneWidget);
    });

    testWidgets('불러오는 중에 화면이 사라져도 오류가 나지 않는다', (tester) async {
      await tester.pumpWidget(
        _app(fakeTmdbService(delay: const Duration(milliseconds: 100))),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });
  });

  group('장르 필터', () {
    testWidgets('장르를 고르면 with_genres로 다시 요청하고, 전체는 with_genres 없이 요청한다', (
      tester,
    ) async {
      final requests = <Uri>[];
      await tester.pumpWidget(_app(fakeTmdbService(requests: requests)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SF'));
      await tester.pumpAndSettle();
      expect(find.text('우주의 끝에서'), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsNothing);

      await tester.tap(find.text('전체'));
      await tester.pumpAndSettle();
      expect(find.text('별빛 아래 우리'), findsOneWidget);

      expect(_discoverGenres(requests), [null, '878', null]);
    });

    testWidgets('선택된 장르를 다시 누르면 선택이 풀려 전체를 요청한다', (tester) async {
      final requests = <Uri>[];
      await tester.pumpWidget(_app(fakeTmdbService(requests: requests)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SF'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SF'));
      await tester.pumpAndSettle();

      expect(_discoverGenres(requests), [null, '878', null]);
      expect(find.text('별빛 아래 우리'), findsOneWidget);
    });

    testWidgets('Discover 요청 중에는 장르를 바꿀 수 없다', (tester) async {
      final requests = <Uri>[];
      await tester.pumpWidget(
        _app(
          fakeTmdbService(
            requests: requests,
            delay: const Duration(milliseconds: 100),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('SF'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 로딩 중 다른 장르를 눌러도 요청하지 않음
      await tester.tap(find.text('드라마'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(_discoverGenres(requests), [null, '878']);
      expect(find.text('우주의 끝에서'), findsOneWidget);
    });
  });

  group('Pull to Refresh', () {
    Future<void> pullToRefresh(WidgetTester tester) async {
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 400),
        1000,
      );
      // 새로고침이 시작될 만큼만 진행
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('선택한 장르 그대로 page 1부터 다시 요청하고, 그동안 기존 목록을 유지한다', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final requests = <Uri>[];
      var results = fakeTmdbMovies;
      await tester.pumpWidget(
        _app(
          fakeTmdbService(
            requests: requests,
            delay: const Duration(seconds: 2),
            resultsBuilder: () => results,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('SF'));
      await tester.pumpAndSettle();
      expect(find.text('우주의 끝에서'), findsOneWidget);

      // 서버의 SF 목록이 바뀐 상태에서 새로고침
      results = [
        ...fakeTmdbMovies,
        {
          'id': 100,
          'title': '새로 나온 SF',
          'genre_ids': [878],
        },
      ];
      requests.clear();
      await pullToRefresh(tester);

      // 새로고침 중: 로딩 화면 대신 기존 목록 유지, 장르 칩은 누를 수 없음
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);
      expect(find.text('우주의 끝에서'), findsOneWidget);
      await tester.tap(find.text('드라마'), warnIfMissed: false);

      await tester.pumpAndSettle();
      expect(_discoverGenres(requests), ['878']);
      expect(requests.single.queryParameters['page'], '1');
      expect(find.text('새로 나온 SF'), findsOneWidget);
    });

    testWidgets('새로고침이 실패하면 기존 목록을 유지한 채 재시도 Dialog를 띄운다', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var failing = false;
      await tester.pumpWidget(_app(fakeTmdbService(fail: () => failing)));
      await tester.pumpAndSettle();

      failing = true;
      await pullToRefresh(tester);
      await tester.pumpAndSettle();

      expect(find.text('영화를 불러오지 못했어요'), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsOneWidget);

      // 네트워크를 다시 켜고 재시도 → Dialog가 닫히고 목록을 다시 불러옴
      failing = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('별빛 아래 우리'), findsOneWidget);
    });

    test('목록 전체를 불러오는 중에는 새로고침하지 않는다', () async {
      final requests = <Uri>[];
      final viewModel = PagedMoviesViewModel(
        fakeTmdbService(requests: requests),
      );

      final loading = viewModel.start();
      await viewModel.refresh();
      await loading;

      // loadInitial의 Discover 요청만 있음
      expect(_discoverGenres(requests), [null]);
    });
  });

  group('요청 실패 재시도 Dialog', () {
    /// 전체 목록을 불러온 뒤 네트워크가 끊긴 상태(goOffline)에서 SF를 선택합니다.
    Future<void> selectSfWhileOffline(
      WidgetTester tester,
      TmdbMovieService service,
      VoidCallback goOffline,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app(service));
      await tester.pumpAndSettle();
      expect(find.text('별빛 아래 우리'), findsOneWidget);

      goOffline();
      await tester.tap(find.text('SF'));
      await tester.pumpAndSettle();
    }

    testWidgets('장르 요청이 실패하면 기존 목록을 유지한 채 Dialog를 띄운다', (tester) async {
      var failing = false;
      await selectSfWhileOffline(
        tester,
        fakeTmdbService(fail: () => failing),
        () => failing = true,
      );

      expect(find.text('영화를 불러오지 못했어요'), findsOneWidget);
      expect(find.text('네트워크 상태를 확인하고\n다시 시도해 주세요.'), findsOneWidget);
      // 최근 성공한 전체 목록이 그대로 남아 있음
      expect(find.text('별빛 아래 우리'), findsOneWidget);

      // W5-01: 326 x 282, 버튼 126 x 52
      final dialogBody = find
          .descendant(of: find.byType(Dialog), matching: find.byType(Material))
          .first;
      expect(tester.getSize(dialogBody), const Size(326, 282));
      final retryButton = find.ancestor(
        of: find.text('다시 시도'),
        matching: find.byType(FilledButton),
      );
      expect(tester.getSize(retryButton), const Size(126, 52));
    });

    testWidgets('다시 시도를 누르면 같은 장르로 page 1부터 다시 요청한다', (tester) async {
      var failing = false;
      final requests = <Uri>[];
      await selectSfWhileOffline(
        tester,
        fakeTmdbService(requests: requests, fail: () => failing),
        () => failing = true,
      );

      // 네트워크를 다시 켜고 재시도
      failing = false;
      requests.clear();
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(_discoverGenres(requests), ['878']);
      expect(requests.first.queryParameters['page'], '1');
      expect(find.text('우주의 끝에서'), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsNothing);
    });

    testWidgets('취소하면 목록과 장르 선택을 실패 전으로 유지하고 다시 요청하지 않는다', (tester) async {
      var failing = false;
      final requests = <Uri>[];
      await selectSfWhileOffline(
        tester,
        fakeTmdbService(requests: requests, fail: () => failing),
        () => failing = true,
      );
      requests.clear();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(requests, isEmpty);
      expect(find.text('별빛 아래 우리'), findsOneWidget);
      // 칩도 목록과 같은 "전체"로 되돌아감
      final allChip = tester.getSemantics(
        find
            .ancestor(of: find.text('전체'), matching: find.byType(Semantics))
            .first,
      );
      expect(allChip.flagsCollection.isSelected, Tristate.isTrue);
      // 실패한 장르는 저장하지 않음
      expect(await GenrePreference().read(), isNull);
    });

    testWidgets('보여줄 목록이 없을 때 실패하면 Dialog 대신 오류 화면을 보여준다', (tester) async {
      await tester.pumpWidget(_app(fakeTmdbService(fail: () => true)));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(find.text('영화 목록을 불러오지 못했습니다.'), findsOneWidget);
    });
  });

  group('더 보기 (page 단위)', () {
    List<Map<String, Object?>> manyMovies(int count) => [
      for (var id = 1; id <= count; id++)
        {'id': id, 'title': '영화 $id', 'genre_ids': <int>[]},
    ];

    List<String?> pages(List<Uri> requests) => [
      for (final uri in requests)
        if (uri.path.endsWith('/discover/movie')) uri.queryParameters['page'],
    ];

    test('첫 page만 요청하고, 더 보기마다 다음 page를 이어 붙인다', () async {
      final requests = <Uri>[];
      final viewModel = PagedMoviesViewModel(
        fakeTmdbService(results: manyMovies(45), requests: requests),
      );

      await viewModel.start();
      expect(viewModel.movies, hasLength(20));
      expect(viewModel.hasMore, isTrue);

      await viewModel.loadNextPage();
      await viewModel.loadNextPage();
      expect(viewModel.movies.map((m) => m.id), [
        for (var i = 1; i <= 45; i++) i,
      ]);
      expect(viewModel.hasMore, isFalse);

      // 마지막 page 뒤에는 더 요청하지 않음
      await viewModel.loadNextPage();
      expect(pages(requests), ['1', '2', '3']);
    });

    test('page 사이에 중복된 영화는 하나만 남긴다', () async {
      // 1페이지 1~20, 2페이지 15~34 (15~20 중복)
      final overlapped = [...manyMovies(20), ...manyMovies(34).skip(14)];
      final viewModel = PagedMoviesViewModel(
        fakeTmdbService(results: overlapped),
      );
      await viewModel.start();
      await viewModel.loadNextPage();

      final ids = viewModel.movies.map((m) => m.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids, hasLength(34));
    });

    test('다음 page 실패는 목록을 유지하고, 다시 시도하면 같은 page를 요청한다', () async {
      final requests = <Uri>[];
      var failing = false;
      final viewModel = PagedMoviesViewModel(
        fakeTmdbService(
          results: manyMovies(30),
          requests: requests,
          fail: () => failing,
        ),
      );
      await viewModel.start();

      failing = true;
      await viewModel.loadNextPage();
      expect(viewModel.loadMoreError, isNotNull);
      expect(viewModel.phase, LoadPhase.ready);
      expect(viewModel.movies, hasLength(20));

      failing = false;
      await viewModel.loadNextPage();
      expect(viewModel.loadMoreError, isNull);
      expect(viewModel.movies, hasLength(30));
      expect(pages(requests), ['1', '2', '2']);
    });

    test('장르를 바꾸면 이전 장르의 늦은 다음 page 응답은 버린다 (generation)', () async {
      final requests = <Uri>[];
      final gate = Completer<void>();
      var holdPage2 = false;
      final base = fakeTmdbService(
        results: [
          ...manyMovies(30),
          {
            'id': 900,
            'title': 'SF 영화',
            'genre_ids': [878],
          },
        ],
        requests: requests,
      );
      final viewModel = PagedMoviesViewModel(
        _GatedService(base, () async {
          if (holdPage2) await gate.future;
        }),
      );
      await viewModel.start();

      holdPage2 = true;
      final loadingMore = viewModel.loadNextPage(); // 전체 2page — 응답 지연
      holdPage2 = false;
      await viewModel.selectGenre(878); // 새 조건
      gate.complete();
      await loadingMore;

      expect(viewModel.movies.map((m) => m.title), ['SF 영화']);
      expect(viewModel.isLoadingMore, isFalse);
      expect(viewModel.hasMore, isFalse);
    });
  });

  group('page 범위', () {
    test('total_pages가 500보다 커도 500 page까지만 요청할 수 있다', () async {
      final viewModel = PagedMoviesViewModel(_FixedPages(totalPages: 900));
      await viewModel.loadInitial();
      expect(viewModel.totalPages, PagedMoviesViewModel.maxTmdbPage);
      expect(viewModel.nextPage, 2);

      // 499 page까지 받았다고 가정 — 500을 받으면 끝
      viewModel.nextPage = 500;
      await viewModel.loadNextPage();
      expect(viewModel.nextPage, 501);
      expect(viewModel.hasMore, isFalse);
    });

    test('응답 page가 요청 page와 다르면 형식 오류로 보고 목록을 바꾸지 않는다', () async {
      final viewModel = PagedMoviesViewModel(
        _FixedPages(totalPages: 3, skew: 1),
      );
      await viewModel.loadInitial();
      expect(viewModel.phase, LoadPhase.error);
    });
  });

  group('더 보기 Footer', () {
    List<Map<String, Object?>> manyMovies(int count) => [
      for (var id = 1; id <= count; id++)
        {'id': id, 'title': '영화 $id', 'genre_ids': <int>[]},
    ];

    Future<void> scrollToFooter(WidgetTester tester) async {
      await tester.scrollUntilVisible(
        find.byType(MoviePageFooter),
        500,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.byType(MoviePageFooter));
      await tester.pumpAndSettle();
    }

    testWidgets('더 보기 → 추가 로딩 → 마지막 페이지 안내', (tester) async {
      await tester.pumpWidget(
        _app(
          fakeTmdbService(
            results: manyMovies(25),
            delay: const Duration(milliseconds: 100),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await scrollToFooter(tester);
      expect(find.text('더 보기'), findsOneWidget);

      await tester.tap(find.text('더 보기'));
      await tester.pump();
      // 추가 로딩 중: 버튼 자리에 로딩, 기존 목록 유지
      expect(
        find.descendant(
          of: find.byType(MoviePageFooter),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(find.text('영화 20', skipOffstage: false), findsOneWidget);

      await tester.pumpAndSettle();
      await scrollToFooter(tester);
      expect(find.text('모든 영화를 확인했습니다.'), findsOneWidget);
      expect(find.text('더 보기'), findsNothing);
    });

    testWidgets('다음 페이지 오류 → 안내와 다음 페이지 다시 시도', (tester) async {
      var failing = false;
      await tester.pumpWidget(
        _app(fakeTmdbService(results: manyMovies(25), fail: () => failing)),
      );
      await tester.pumpAndSettle();
      await scrollToFooter(tester);

      failing = true;
      await tester.tap(find.text('더 보기'));
      await tester.pumpAndSettle();
      expect(find.text('추가 영화 조회에 실패했습니다.'), findsOneWidget);
      expect(find.byType(Dialog), findsNothing); // 다음 page 실패는 Dialog가 아님

      failing = false;
      await tester.tap(find.text('다음 페이지 다시 시도'));
      await tester.pumpAndSettle();
      await scrollToFooter(tester);
      expect(find.text('모든 영화를 확인했습니다.'), findsOneWidget);
    });
  });

  group('마지막 선택 장르', () {
    testWidgets('선택한 장르 id를 저장하고, 다시 들어오면 그 장르로 요청한다', (tester) async {
      final requests = <Uri>[];
      await tester.pumpWidget(
        _app(fakeTmdbService(requests: requests), key: UniqueKey()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('SF'));
      await tester.pumpAndSettle();

      expect(await GenrePreference().read(), 878);

      // 새 화면으로 다시 들어오기
      requests.clear();
      await tester.pumpWidget(
        _app(fakeTmdbService(requests: requests), key: UniqueKey()),
      );
      await tester.pumpAndSettle();
      expect(_discoverGenres(requests), ['878']);
      expect(find.text('우주의 끝에서'), findsOneWidget);
      expect(find.text('별빛 아래 우리'), findsNothing);
    });

    test('저장된 값이 없거나 전체를 고르면 null을 돌려준다', () async {
      final preference = GenrePreference();
      expect(await preference.read(), isNull);

      await preference.save(18);
      expect(await preference.read(), 18);
      await preference.save(null);
      expect(await preference.read(), isNull);
    });
  });

  group('재설치 후 Secure Storage 정리', () {
    test('처음 실행할 때만 이전 설치의 값을 지운다', () async {
      FlutterSecureStorage.setMockInitialValues({'access_token': 'old'});
      const secureStorage = FlutterSecureStorage();

      await clearStaleSecureStorageOnFirstInstall();
      expect(await secureStorage.read(key: 'access_token'), isNull);
      expect(await SharedPreferencesAsync().getBool(firstInstallKey), isTrue);

      // 두 번째 실행부터는 로그인 후 저장한 값을 유지
      await secureStorage.write(key: 'access_token', value: 'new');
      await clearStaleSecureStorageOnFirstInstall();
      expect(await secureStorage.read(key: 'access_token'), 'new');
    });
  });
}

/// discoverMovies의 2page 이후 요청을 [hold]가 끝날 때까지 늦추는 Service — 늦은 응답 확인용
class _GatedService extends TmdbMovieService {
  _GatedService(this._inner, this._hold) : super(Dio());

  final TmdbMovieService _inner;
  final Future<void> Function() _hold;

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    int? genreId,
  }) async {
    if (page > 1) await _hold();
    return _inner.discoverMovies(page: page, genreId: genreId);
  }

  @override
  Future<List<TmdbGenreDto>> fetchGenres() => _inner.fetchGenres();
}

/// 요청한 page를 그대로(또는 [skew]만큼 어긋나게) 돌려주는 Discover — page 범위 확인용
class _FixedPages extends TmdbMovieService {
  _FixedPages({required this.totalPages, this.skew = 0}) : super(Dio());

  final int totalPages;
  final int skew;

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    int? genreId,
  }) async => TmdbMoviePageDto(
    page: page + skew,
    results: [
      TmdbMovieDto(
        id: page,
        title: '영화 $page',
        overview: '',
        posterPath: null,
        backdropPath: null,
        releaseDate: null,
        genreIds: const [],
        voteAverage: 0,
        popularity: 0,
      ),
    ],
    totalPages: totalPages,
    totalResults: totalPages,
  );
}
