import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../data/local/genre_preference.dart';
import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/models/tmdb_movie_page.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';

export 'load_phase.dart';

/// 목록 조건 — 장르(Discover)와 검색어(Search). 검색어가 있으면 Search API를 씁니다.
typedef MovieCondition = ({int? genreId, String query});

/// 영화 목록·검색의 page 상태 (9주차) — 5주차의 "Discover 최대 30개 수집"을 대체합니다.
///
/// | 상태값            | 역할                                                   |
/// | ----------------- | ------------------------------------------------------ |
/// | [movies]          | 현재 표시 중인 영화 목록                               |
/// | [nextPage]        | 다음에 요청할 page — 실패하면 그대로 둡니다            |
/// | [totalPages]      | 서버 total_pages와 TMDB 최대 500 중 작은 값            |
/// | [hasMore]         | 다음 요청 가능 여부                                    |
/// | [isLoadingMore]   | 다음 page를 요청 중인지                                |
/// | [loadMoreError]   | 기존 목록을 지우지 않고 하단에 보여줄 오류             |
/// | [_requestGeneration] | 조건이 바뀌었는지 검사                              |
///
/// 1. 첫 page 성공 → 목록 교체  2. 더 보기 → 버튼 비활성 + 로딩
/// 3. 성공 → 같은 movieId 제외하고 append, nextPage 증가
/// 4. 실패 → 목록과 nextPage 유지, 같은 page 재시도
/// 5. 마지막 page → 더 보기 숨기고 끝 상태
/// 6. 장르·검색어·refresh 변경 → generation 증가, page·추가 로딩 상태 reset, 새 첫 page 요청
///
/// 영화 목록과 검색 화면은 이 클래스를 각각 별도 인스턴스로 씁니다.
///
/// 5주차 동작 유지(영화 목록): 장르 목록·마지막 선택 장르 저장([start]), Pull to Refresh,
/// 장르 변경·새로고침 실패 시 보이던 목록을 유지한 채 재시도 Dialog([retryDialogVisible]).
class PagedMoviesViewModel extends ChangeNotifier with SafeNotify {
  PagedMoviesViewModel(this.tmdbApi, {GenrePreference? genrePreference})
    : _genrePreference = genrePreference ?? GenrePreference();

  final TmdbMovieService tmdbApi;
  final GenrePreference _genrePreference;

  /// TMDB page는 1~500까지입니다. total_pages가 더 커도 501은 요청하지 않습니다.
  static const maxTmdbPage = 500;

  LoadPhase phase = LoadPhase.idle;
  List<TmdbMovieDto> movies = const [];
  int nextPage = 1;
  int totalPages = 1;
  bool isLoadingMore = false;
  bool get hasMore => nextPage <= totalPages;
  String? errorMessage;
  String? loadMoreError;
  int _requestGeneration = 0;

  /// 화면의 [movies]를 불러온 조건 — 다음 page는 이 조건으로 이어서 요청합니다.
  MovieCondition _condition = (genreId: null, query: '');
  MovieCondition get condition => _condition;

  // ---- 영화 목록 전용 (5주차) ----

  List<TmdbGenreDto> genres = const [];

  /// 칩에 표시할 장르 — 실패해 이전 목록을 보여주는 동안에는 [_condition]과 다를 수 있습니다.
  int? selectedGenreId;

  /// Pull to Refresh 중 — 기존 목록은 화면에 그대로 둡니다.
  bool isRefreshing = false;

  /// 장르를 바꾸다(또는 새로고침하다) 실패했지만 이전 목록이 있어 그대로 보여주는 중 — 재시도 Dialog
  bool retryDialogVisible = false;

  bool get isLoading => phase == LoadPhase.idle || phase == LoadPhase.loading;

  /// 첫 page 요청 중(로딩·새로고침)에는 장르를 바꿀 수 없습니다.
  bool get isRequesting => isLoading || isRefreshing;

  /// 장르 id → 이름 (영화 카드 소제목용)
  Map<int, String> get genreNames => {
    for (final genre in genres) genre.id: genre.name,
  };

  /// 영화 목록 첫 진입·오류 다시 시도 — 장르 목록과 마지막으로 선택한 장르의 첫 page
  Future<void> start() async {
    final generation = ++_requestGeneration;
    phase = LoadPhase.loading;
    errorMessage = null;
    notifyIfAlive();
    try {
      genres = await tmdbApi.fetchGenres();
      final savedGenreId = await _genrePreference.read();
      if (generation != _requestGeneration || isDisposed) return;
      // 저장된 장르가 지금 장르 목록에 없으면 전체로 시작합니다.
      selectedGenreId = genres.any((genre) => genre.id == savedGenreId)
          ? savedGenreId
          : null;
    } catch (_) {
      if (generation != _requestGeneration || isDisposed) return;
      phase = LoadPhase.error;
      errorMessage = '영화 목록을 불러오지 못했습니다.';
      notifyIfAlive();
      return;
    }
    await loadInitial(genreId: selectedGenreId);
  }

  /// 장르 선택 — null이면 전체. 성공한 장르만 다음 진입 때 이어서 보여주도록 저장합니다.
  Future<void> selectGenre(int? genreId) async {
    if (isRequesting) return;
    selectedGenreId = genreId;
    await loadInitial(genreId: genreId);
    if (!isDisposed && phase != LoadPhase.error && !retryDialogVisible) {
      unawaited(_genrePreference.save(genreId));
    }
  }

  // ---- 공통 ----

  /// 새 조건의 첫 page — generation을 올리고 page·추가 로딩 상태를 초기화합니다.
  ///
  /// 영화 목록에서 실패했는데 보이던 목록이 있으면, 그 목록으로 되돌리고 재시도 Dialog를 띄웁니다.
  Future<void> loadInitial({int? genreId, String query = ''}) async {
    if (isDisposed) return;
    final requested = (genreId: genreId, query: query.trim());
    final generation = ++_requestGeneration;
    final previous = (
      movies: movies,
      condition: _condition,
      nextPage: nextPage,
      totalPages: totalPages,
    );
    phase = LoadPhase.loading;
    errorMessage = null;
    loadMoreError = null;
    isLoadingMore = false;
    movies = const [];
    nextPage = 1;
    totalPages = 1;
    notifyIfAlive();

    try {
      final page = await _fetchPage(1, requested);
      if (generation != _requestGeneration || isDisposed) return;
      _condition = requested;
      _applyFirstPage(page);
    } catch (_) {
      if (generation != _requestGeneration || isDisposed) return;
      if (previous.movies.isNotEmpty && requested.query.isEmpty) {
        // 5주차 Challenge — 보이던 목록과 page 상태를 되돌리고 재시도 Dialog
        movies = previous.movies;
        _condition = previous.condition;
        nextPage = previous.nextPage;
        totalPages = previous.totalPages;
        phase = LoadPhase.ready;
        retryDialogVisible = true;
      } else {
        phase = LoadPhase.error;
        errorMessage = requested.query.isEmpty
            ? '영화 목록을 불러오지 못했습니다.'
            : '검색 결과를 불러오지 못했습니다.';
      }
    } finally {
      if (generation == _requestGeneration && !isDisposed) notifyIfAlive();
    }
  }

  /// 더 보기 — 실패해도 nextPage를 올리지 않아 같은 page를 다시 요청할 수 있습니다.
  Future<void> loadNextPage() async {
    if (isDisposed ||
        isLoadingMore ||
        isRefreshing ||
        !hasMore ||
        phase != LoadPhase.ready) {
      return;
    }
    final generation = _requestGeneration;
    final pageToLoad = nextPage;
    isLoadingMore = true;
    loadMoreError = null;
    notifyIfAlive();
    try {
      final page = await _fetchPage(pageToLoad, _condition);
      if (generation != _requestGeneration || isDisposed) return;
      _appendPage(page);
    } catch (_) {
      if (generation != _requestGeneration || isDisposed) return;
      loadMoreError = _condition.query.isEmpty
          ? '추가 영화 조회에 실패했습니다.'
          : '추가 검색 결과 조회에 실패했습니다.';
    } finally {
      // 조건이 바뀌었으면 새 조건의 상태를 건드리지 않습니다.
      if (generation == _requestGeneration && !isDisposed) {
        isLoadingMore = false;
        notifyIfAlive();
      }
    }
  }

  /// Pull to Refresh — 지금 목록의 조건으로 첫 page부터 다시. 그동안 보이던 목록을 유지합니다.
  Future<void> refresh() async {
    if (isRequesting) return;
    final target = _condition;
    final generation = ++_requestGeneration;
    isRefreshing = true;
    isLoadingMore = false;
    loadMoreError = null;
    notifyIfAlive();
    try {
      final page = await _fetchPage(1, target);
      if (generation != _requestGeneration || isDisposed) return;
      movies = const [];
      _applyFirstPage(page);
    } catch (_) {
      if (generation != _requestGeneration || isDisposed) return;
      if (movies.isNotEmpty) {
        retryDialogVisible = true;
      } else {
        phase = LoadPhase.error;
        errorMessage = '영화 목록을 불러오지 못했습니다.';
      }
    } finally {
      if (generation == _requestGeneration && !isDisposed) {
        isRefreshing = false;
        notifyIfAlive();
      }
    }
  }

  /// 재시도 Dialog의 다시 시도 — 칩에 선택된 장르의 첫 page
  Future<void> retryLastRequest() {
    retryDialogVisible = false;
    return selectGenre(selectedGenreId);
  }

  /// 재시도 Dialog의 취소 — 목록은 그대로 두고, 칩을 목록의 장르로 되돌립니다.
  void cancelRetry() {
    retryDialogVisible = false;
    selectedGenreId = _condition.genreId;
    notifyIfAlive();
  }

  Future<TmdbMoviePageDto> _fetchPage(
    int page,
    MovieCondition condition,
  ) async {
    final result = condition.query.isNotEmpty
        ? await tmdbApi.searchMovies(page: page, query: condition.query)
        : await tmdbApi.discoverMovies(page: page, genreId: condition.genreId);
    if (result.page != page || result.page < 1 || result.totalPages < 0) {
      throw const FormatException('TMDB page metadata is inconsistent.');
    }
    return result;
  }

  void _applyFirstPage(TmdbMoviePageDto page) {
    movies = _dedupe(page.results);
    _updatePages(page);
    phase = movies.isEmpty ? LoadPhase.empty : LoadPhase.ready;
  }

  void _appendPage(TmdbMoviePageDto page) {
    movies = [...movies, ..._dedupe(page.results)];
    _updatePages(page);
  }

  void _updatePages(TmdbMoviePageDto page) {
    totalPages = page.totalPages > maxTmdbPage ? maxTmdbPage : page.totalPages;
    // 결과가 비어 있으면 total_pages와 관계없이 더 요청하지 않습니다.
    if (page.results.isEmpty) totalPages = page.page;
    nextPage = page.page + 1;
  }

  /// page가 넘어가는 사이 순위가 바뀌어 같은 영화가 다시 올 수 있어 movieId로 거릅니다.
  List<TmdbMovieDto> _dedupe(List<TmdbMovieDto> incoming) {
    final seen = movies.map((movie) => movie.id).toSet();
    return incoming.where((movie) => seen.add(movie.id)).toList();
  }

  @override
  void dispose() {
    _requestGeneration++;
    super.dispose();
  }
}
