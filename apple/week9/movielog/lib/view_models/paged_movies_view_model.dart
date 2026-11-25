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
typedef MovieCriteria = ({int? genreId, String query});

/// 영화 목록·검색의 page 상태 (9주차) — 5주차의 "Discover 최대 30개 수집"을 대체합니다.
///
/// - 첫 page만 불러오고, "더 보기"([loadMore])를 누를 때마다 다음 page를 이어 붙입니다.
/// - 마지막 page면 [hasMore]가 false — 화면은 "모든 영화를 확인했습니다."를 보여줍니다.
/// - 다음 page 실패는 목록을 지우지 않고 [loadMoreFailed]로 표시해 그 page만 다시 시도합니다.
/// - 장르·검색어가 바뀌면 [_generation]을 올리고, 응답/오류/finally는 요청 시점의 값과 같을 때만 반영합니다.
///   (취소되지 않은 이전 조건의 느린 응답이 새 결과를 덮어쓰지 않게)
/// - page가 넘어가는 사이 순위가 바뀌어 같은 영화가 다시 올 수 있어 id로 중복을 거릅니다.
///
/// 5주차 동작 유지: 장르 목록·마지막 선택 장르 저장, Pull to Refresh,
/// 장르 변경·새로고침 실패 시 기존 목록을 유지한 채 재시도 Dialog.
class PagedMoviesViewModel extends ChangeNotifier with SafeNotify {
  PagedMoviesViewModel(this._service, {GenrePreference? genrePreference})
    : _genrePreference = genrePreference ?? GenrePreference();

  final TmdbMovieService _service;
  final GenrePreference _genrePreference;

  LoadPhase phase = LoadPhase.idle;
  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];
  String? message;

  /// 사용자가 고른 현재 조건 — 실패해 이전 목록을 보여주는 동안에는 [_loaded]와 다를 수 있습니다.
  MovieCriteria criteria = (genreId: null, query: '');

  /// 화면의 [movies]를 불러온 조건과 page — 다음 page는 이 조건으로 이어서 요청합니다.
  MovieCriteria _loaded = (genreId: null, query: '');
  int _page = 0;
  int _totalPages = 0;

  /// 다음 page를 불러오는 중 — ready 목록은 그대로 둡니다.
  bool isLoadingMore = false;

  /// 다음 page 요청 실패 — 목록 아래에 "다음 페이지 다시 시도"
  bool loadMoreFailed = false;

  /// Pull to Refresh 중 — 기존 목록은 화면에 그대로 둡니다.
  bool isRefreshing = false;

  /// 장르를 바꾸다(또는 새로고침하다) 실패했지만 이전 목록이 있어 그대로 보여주는 중 — 재시도 Dialog
  bool retryDialogVisible = false;

  int _generation = 0;

  int? get selectedGenreId => criteria.genreId;

  bool get hasMore => _page < _totalPages;

  bool get isLoading => phase == LoadPhase.idle || phase == LoadPhase.loading;

  /// 첫 page 요청 중(로딩·새로고침)에는 장르를 바꿀 수 없습니다.
  bool get isRequesting => isLoading || isRefreshing;

  /// 장르 id → 이름 (영화 카드 소제목용)
  Map<int, String> get genreNames => {
    for (final genre in genres) genre.id: genre.name,
  };

  Future<TmdbMoviePageDto> _fetch(MovieCriteria c, int page) =>
      c.query.isNotEmpty
      ? _service.searchMovies(query: c.query, page: page)
      : _service.discoverMovies(page: page, genreId: c.genreId);

  /// 영화 목록 첫 진입·다시 시도 — 장르 목록과 마지막으로 선택한 장르의 첫 page
  Future<void> loadInitial() async {
    final generation = ++_generation;
    phase = LoadPhase.loading;
    message = null;
    notifyIfAlive();
    try {
      genres = await _service.fetchGenres();
      final savedGenreId = await _genrePreference.read();
      if (isDisposed || generation != _generation) return;
      // 저장된 장르가 지금 장르 목록에 없으면 전체로 시작합니다.
      final genreId = genres.any((genre) => genre.id == savedGenreId)
          ? savedGenreId
          : null;
      criteria = (genreId: genreId, query: '');
    } catch (_) {
      if (isDisposed || generation != _generation) return;
      phase = LoadPhase.error;
      message = '영화를 불러오지 못했어요. 다시 시도해 주세요.';
      notifyIfAlive();
      return;
    }
    await _loadFirstPage(criteria, generation: generation);
  }

  /// 장르 선택 — null이면 전체. 새 조건의 첫 page부터 다시 조회합니다.
  Future<void> selectGenre(int? genreId) async {
    if (isRequesting) return;
    criteria = (genreId: genreId, query: '');
    await _loadFirstPage(criteria, saveGenre: true);
  }

  /// 검색 — 앞뒤 공백을 지운 검색어의 첫 page. 빈 검색어는 요청하지 않습니다.
  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    criteria = (genreId: null, query: trimmed);
    await _loadFirstPage(criteria);
  }

  /// 첫 조회 오류 화면의 다시 시도 — 현재 조건 그대로
  Future<void> retry() => genres.isEmpty && criteria.query.isEmpty
      ? loadInitial()
      : _loadFirstPage(criteria);

  /// 조건의 첫 page — 새 generation으로 이전 조건의 응답(다음 page 포함)을 모두 무효로 만듭니다.
  Future<void> _loadFirstPage(
    MovieCriteria target, {
    int? generation,
    bool saveGenre = false,
  }) async {
    final requestedAt = generation ?? ++_generation;
    phase = LoadPhase.loading;
    message = null;
    isLoadingMore = false;
    loadMoreFailed = false;
    notifyIfAlive();

    try {
      final page = await _fetch(target, 1);
      if (isDisposed || requestedAt != _generation) return;
      _applyFirstPage(target, page);
      // 불러오기에 성공한 장르만 다음 진입 때 이어서 보여줍니다.
      if (saveGenre) unawaited(_genrePreference.save(target.genreId));
    } catch (_) {
      if (isDisposed || requestedAt != _generation) return;
      // 영화 목록: 이전 목록이 있으면 비우지 않고 재시도 Dialog (5주차 Challenge 유지)
      if (movies.isNotEmpty && target.query.isEmpty) {
        phase = LoadPhase.ready;
        retryDialogVisible = true;
      } else {
        phase = LoadPhase.error;
        message = target.query.isNotEmpty
            ? '검색 결과를 불러오지 못했습니다.'
            : '영화를 불러오지 못했어요. 다시 시도해 주세요.';
      }
    }
    notifyIfAlive();
  }

  void _applyFirstPage(MovieCriteria target, TmdbMoviePageDto page) {
    final byId = <int, TmdbMovieDto>{
      for (final movie in page.results) movie.id: movie,
    };
    movies = byId.values.toList();
    _loaded = target;
    _page = page.page;
    _totalPages = page.results.isEmpty ? page.page : page.totalPages;
    phase = movies.isEmpty ? LoadPhase.empty : LoadPhase.ready;
  }

  /// 더 보기 — 화면의 목록을 불러온 조건([_loaded])으로 다음 page를 이어 붙입니다.
  Future<void> loadMore() async {
    if (phase != LoadPhase.ready || isLoadingMore || isRefreshing || !hasMore) {
      return;
    }
    final requestedAt = _generation;
    final target = _loaded;
    final nextPage = _page + 1;
    isLoadingMore = true;
    loadMoreFailed = false;
    notifyIfAlive();

    try {
      final page = await _fetch(target, nextPage);
      if (isDisposed || requestedAt != _generation) return;
      final seen = {for (final movie in movies) movie.id};
      movies = [
        ...movies,
        for (final movie in page.results)
          if (seen.add(movie.id)) movie,
      ];
      _page = page.page;
      // 결과가 비어 있으면 total_pages와 관계없이 더 요청하지 않습니다.
      _totalPages = page.results.isEmpty ? page.page : page.totalPages;
    } catch (_) {
      if (isDisposed || requestedAt != _generation) return;
      loadMoreFailed = true;
    } finally {
      // 조건이 바뀌었으면 새 조건의 상태를 건드리지 않습니다.
      if (!isDisposed && requestedAt == _generation) isLoadingMore = false;
    }
    notifyIfAlive();
  }

  /// Pull to Refresh — 지금 목록의 조건으로 첫 page부터 다시. 실패하면 기존 목록 유지 + 재시도 Dialog
  Future<void> refresh() async {
    if (isRequesting) return;
    final target = _loaded;
    final requestedAt = ++_generation;
    isRefreshing = true;
    isLoadingMore = false;
    loadMoreFailed = false;
    notifyIfAlive();

    try {
      final page = await _fetch(target, 1);
      if (isDisposed || requestedAt != _generation) return;
      _applyFirstPage(target, page);
    } catch (_) {
      if (isDisposed || requestedAt != _generation) return;
      if (movies.isNotEmpty) {
        retryDialogVisible = true;
      } else {
        phase = LoadPhase.error;
        message = '영화를 불러오지 못했어요. 다시 시도해 주세요.';
      }
    } finally {
      if (!isDisposed && requestedAt == _generation) isRefreshing = false;
    }
    notifyIfAlive();
  }

  /// 재시도 Dialog의 다시 시도 — 마지막으로 선택한 조건의 첫 page
  Future<void> retryLastRequest() {
    retryDialogVisible = false;
    return _loadFirstPage(criteria, saveGenre: criteria.query.isEmpty);
  }

  /// 재시도 Dialog의 취소 — 목록은 그대로 두고, 칩을 목록의 조건으로 되돌립니다.
  void cancelRetry() {
    retryDialogVisible = false;
    criteria = _loaded;
    notifyIfAlive();
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }
}
