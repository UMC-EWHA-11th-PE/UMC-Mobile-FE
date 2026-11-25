import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/session/session_guard.dart';
import '../core/utils/map_bounded.dart';
import '../core/utils/safe_notify.dart';
import '../data/models/favorite_list_item.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';

export 'load_phase.dart';

/// 내 즐겨찾기 화면의 상태 (9주차)
///
/// 1. MovieLog `GET /v8/favorites`(JWT)로 favoriteId·movieId·createdAt 목록을 받습니다.
/// 2. 목록을 먼저 보여준 뒤, 영화마다 TMDB `/movie/{id}`로 제목·포스터를 가져와 movieId로 합칩니다.
///    - `mapBounded`로 한 번에 최대 5개만 요청합니다. (즐겨찾기가 100개여도)
///    - 카드 하나가 실패해도 전체를 실패로 만들지 않고 그 카드만 [FavoriteListItem.movieFailed]로 표시합니다.
///    - 실패한 카드는 [retryMovie]로 그 카드만 다시 조회합니다.
///
/// 사용자별 즐겨찾기([items])와 TMDB 공개 영화 정보([_movieById])는 같은 Map에 보관하지 않습니다.
/// 계정별 상태라 Route에서 `ValueKey('email:generation')`으로 만들어, 계정이 바뀌면 새로 만듭니다.
class FavoritesViewModel extends ChangeNotifier with SafeNotify {
  FavoritesViewModel(
    this._api,
    this._tmdb, {
    required SessionGuard guard,
    this.onSessionExpired,
    this.concurrency = 5,
  }) : _guard = guard,
       _generation = guard.generation,
       _accountId = guard.accountId;

  final FavoriteApiService _api;
  final TmdbMovieService _tmdb;
  final SessionGuard _guard;
  final Future<void> Function()? onSessionExpired;

  /// TMDB 동시 요청 수
  final int concurrency;

  final int _generation;
  final String? _accountId;

  LoadPhase phase = LoadPhase.idle;
  List<FavoriteListItem> items = const [];
  String? message;

  /// TMDB 공개 영화 정보 — movieId로 찾습니다. 다시 불러올 때 이미 받은 영화는 재요청하지 않습니다.
  final Map<int, TmdbMovieDto> _movieById = {};

  /// 목록 요청마다 1씩 올려, 늦게 도착한 이전 목록 요청의 결과를 무시합니다.
  int _loadVersion = 0;

  bool get _isSessionCurrent {
    final account = _accountId;
    return !isDisposed &&
        account != null &&
        _guard.isCurrent(_generation, account);
  }

  /// 목록 조회 — [silent]면(상세에서 돌아왔을 때) 로딩 없이 기존 목록을 둔 채 새로 맞춥니다.
  Future<void> load({bool silent = false}) async {
    if (_accountId == null) return;
    final version = ++_loadVersion;
    final showLoading = !silent || phase != LoadPhase.ready;
    if (showLoading) {
      phase = LoadPhase.loading;
      message = null;
      notifyIfAlive();
    }

    bool isCurrent() => _isSessionCurrent && version == _loadVersion;

    final List<FavoriteListItem> fetched;
    try {
      final favorites = await _api.fetchMyFavorites();
      if (!isCurrent()) return;
      fetched = [
        for (final favorite in favorites)
          FavoriteListItem(
            favorite: favorite,
            movie: _movieById[favorite.movieId],
          ),
      ];
    } on DioException catch (error) {
      if (!isCurrent()) return;
      final code = apiErrorCode(error);
      if (isSessionExpiredCode(code)) {
        await onSessionExpired?.call();
        return;
      }
      if (!showLoading) return; // 조용한 새로고침 실패 — 보이던 목록 유지
      phase = LoadPhase.error;
      message = code == 'MEMBER404_1'
          ? '회원 정보를 찾을 수 없습니다.'
          : '즐겨찾기를 불러오지 못했습니다.';
      notifyIfAlive();
      return;
    } catch (_) {
      if (!isCurrent()) return;
      if (!showLoading) return;
      phase = LoadPhase.error;
      message = '즐겨찾기를 불러오지 못했습니다.';
      notifyIfAlive();
      return;
    }

    items = fetched;
    phase = fetched.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    notifyIfAlive();

    // 아직 TMDB 정보가 없는 영화만 최대 [concurrency]개씩 가져옵니다.
    final missing = [
      for (final item in fetched)
        if (item.movie == null) item.movieId,
    ];
    if (missing.isEmpty) return;

    // 카드별 실패를 null 결과로 바꿔, 하나가 실패해도 나머지 결과를 받습니다.
    final results = await mapBounded<int, TmdbMovieDto?>(
      missing,
      _fetchMovieOrNull,
      concurrency: concurrency,
    );
    if (!isCurrent()) return;

    final failed = <int>{};
    for (var i = 0; i < missing.length; i++) {
      final movie = results[i];
      if (movie == null) {
        failed.add(missing[i]);
      } else {
        _movieById[missing[i]] = movie;
      }
    }
    items = [
      for (final item in items)
        if (_movieById[item.movieId] case final movie?)
          item.withMovie(movie)
        else if (failed.contains(item.movieId))
          item.withMovieFailed()
        else
          item,
    ];
    notifyIfAlive();
  }

  /// 실패한 카드 하나만 TMDB를 다시 조회합니다.
  Future<void> retryMovie(int movieId) async {
    final index = items.indexWhere((item) => item.movieId == movieId);
    if (index < 0 || !items[index].movieFailed) return;
    final version = _loadVersion;
    _replace(movieId, (item) => item.withMovieLoading());

    final movie = await _fetchMovieOrNull(movieId);
    if (!_isSessionCurrent || version != _loadVersion) return;
    if (movie != null) _movieById[movieId] = movie;
    _replace(
      movieId,
      (item) => movie != null ? item.withMovie(movie) : item.withMovieFailed(),
    );
  }

  void _replace(int movieId, FavoriteListItem Function(FavoriteListItem) f) {
    items = [
      for (final item in items) item.movieId == movieId ? f(item) : item,
    ];
    notifyIfAlive();
  }

  Future<TmdbMovieDto?> _fetchMovieOrNull(int movieId) async {
    try {
      return await _tmdb.fetchMovie(movieId);
    } catch (_) {
      return null;
    }
  }
}
