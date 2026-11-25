import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:movielog/app/movie_log_app.dart';
import 'package:movielog/data/models/tmdb_movie_page.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/movie_search_screen.dart';
import 'package:movielog/theme/app_theme.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';

import 'fake_auth.dart';
import 'fake_favorites.dart';
import 'fake_tmdb.dart';

Widget _app(TmdbMovieService service) => MaterialApp(
  theme: AppTheme.light,
  home: ChangeNotifierProvider<PagedMoviesViewModel>(
    create: (_) => PagedMoviesViewModel(service),
    child: const MovieSearchScreen(),
  ),
);

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.tap(find.text('검색'));
  await tester.pumpAndSettle();
}

/// 검색어별로 응답을 늦출 수 있는 Service — 늦게 도착한 이전 검색 응답 확인용
class _SlowSearch extends TmdbMovieService {
  _SlowSearch(this._inner, this.holds) : super(Dio());

  final TmdbMovieService _inner;
  final Map<String, Future<void>> holds;

  @override
  Future<TmdbMoviePageDto> searchMovies({
    required String query,
    required int page,
  }) async {
    await holds[query];
    return _inner.searchMovies(query: query, page: page);
  }
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('검색어가 바뀌면 이전 검색어의 늦은 응답은 반영하지 않는다', () async {
    final slow = Completer<void>();
    final viewModel = PagedMoviesViewModel(
      _SlowSearch(fakeTmdbService(), {'별빛': slow.future}),
    );

    final first = viewModel.search('별빛');
    await viewModel.search('우주');
    slow.complete();
    await first;

    expect(viewModel.criteria.query, '우주');
    expect(viewModel.movies.map((m) => m.title), ['우주의 끝에서']);
  });

  test('빈 검색어는 요청하지 않는다', () async {
    final requests = <Uri>[];
    final viewModel = PagedMoviesViewModel(fakeTmdbService(requests: requests));
    await viewModel.search('   ');
    expect(requests, isEmpty);
    expect(viewModel.phase, LoadPhase.idle);
  });

  testWidgets('검색 결과 → 검색 결과 더 보기', (tester) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final requests = <Uri>[];
    final results = [
      for (var id = 1; id <= 25; id++)
        {'id': id, 'title': '별빛 $id', 'genre_ids': <int>[]},
    ];
    await tester.pumpWidget(
      _app(fakeTmdbService(results: results, requests: requests)),
    );

    expect(find.text('영화 검색'), findsOneWidget);
    await _search(tester, ' 별빛 ');
    expect(requests.single.path, endsWith('/search/movie'));
    expect(requests.single.queryParameters['query'], '별빛');

    await tester.scrollUntilVisible(
      find.text('검색 결과 더 보기'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('검색 결과 더 보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('검색 결과 더 보기'));
    await tester.pumpAndSettle();

    expect(requests.last.queryParameters['page'], '2');
    expect(find.text('검색 결과 더 보기'), findsNothing);
  });

  testWidgets('검색 빈 결과', (tester) async {
    await tester.pumpWidget(_app(fakeTmdbService()));
    await _search(tester, '없는 영화 제목');
    expect(find.text('검색 결과가 없습니다.'), findsOneWidget);
  });

  testWidgets('검색 오류 → 다시 시도', (tester) async {
    var failing = true;
    await tester.pumpWidget(_app(fakeTmdbService(fail: () => failing)));
    await _search(tester, '별빛');
    expect(find.text('검색 결과를 불러오지 못했습니다.'), findsOneWidget);

    failing = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('별빛 아래 우리'), findsOneWidget);
  });

  testWidgets('영화 탭 헤더의 검색 → 하단 탭 없는 검색 화면, 뒤로가면 목록', (tester) async {
    await tester.pumpWidget(
      MovieLogApp(
        favoriteApiService: FakeFavoriteServer().service,
        authViewModel: await signedInAuth(),
        tmdbMovieService: fakeTmdbService(),
      ),
    );
    await tester.pumpAndSettle();
    appRouter(tester).go('/movies');
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('검색'));
    await tester.pumpAndSettle();
    expect(find.byType(MovieSearchScreen), findsOneWidget);
    expect(find.text('마이'), findsNothing);

    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(find.byType(MovieSearchScreen), findsNothing);
    expect(find.text('마이'), findsOneWidget);
  });
}
