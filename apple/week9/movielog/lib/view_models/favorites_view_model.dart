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
/// 2. 영화마다 TMDB `/movie/{id}`로 제목·포스터를 보충해 movieId로 합칩니다.
///    - `mapBounded`로 한 번에 최대 [enrichmentConcurrency](5)개만 요청합니다.
///    - 카드 하나가 실패해도 목록 전체를 실패로 만들지 않고 그 카드에만 [FavoriteListItem.errorMessage]를 둡니다.
///    - 실패한 카드는 [retryMovie]로 그 카드만 다시 조회합니다.
///
/// 목록 조회 전체 실패([LoadPhase.error])와 영화 한 건의 정보 실패(카드 placeholder)는 다릅니다.
/// 사용자별 즐겨찾기([items])와 TMDB 공개 영화 정보([_movieById])는 같은 Map에 보관하지 않습니다.
class FavoritesViewModel extends ChangeNotifier with SafeNotify {
  FavoritesViewModel({
    required this.favoriteApi,
    required this.tmdbApi,
    required this.sessionGuard,
    required this.accountId,
    this.enrichmentConcurrency = 5,
    this.onSessionExpired,
  });

  final FavoriteApiService favoriteApi;
  final TmdbMovieService tmdbApi;
  final SessionGuard sessionGuard;

  /// `/members/me`로 확인한 email — 화면 쪽 세션 구분에만 씁니다.
  final String accountId;
  final int enrichmentConcurrency;
  final Future<void> Function()? onSessionExpired;

  LoadPhase phase = LoadPhase.idle;
  List<FavoriteListItem> items = const [];
  String? errorMessage;

  static const movieErrorMessage = '영화 정보를 불러오지 못했습니다.';

  /// TMDB 공개 영화 정보 — 다시 조회할 때 이미 받은 영화는 재요청하지 않습니다.
  final Map<int, TmdbMovieDto> _movieById = {};

  /// 목록 요청마다 1씩 올려, 늦게 도착한 이전 목록 요청의 결과를 무시합니다.
  int _refreshGeneration = 0;

  bool _isCurrent(int sessionGeneration, int refreshGeneration) =>
      sessionGuard.isCurrent(sessionGeneration, accountId) &&
      refreshGeneration == _refreshGeneration &&
      !isDisposed;

  /// 즐겨찾기 목록을 다시 조회하고 TMDB 영화 정보를 최대 5개씩 보충합니다.
  ///
  /// [silent]면(상세에서 돌아왔을 때) 로딩 없이 보이던 목록을 둔 채 새로 맞추고,
  /// 실패해도 보이던 목록을 유지합니다.
  Future<void> refresh({bool silent = false}) async {
    final sessionGeneration = sessionGuard.generation;
    if (!sessionGuard.isCurrent(sessionGeneration, accountId) || isDisposed) {
      return;
    }
    final refreshGeneration = ++_refreshGeneration;
    final showLoading = !silent || phase != LoadPhase.ready;
    if (showLoading) {
      phase = LoadPhase.loading;
      errorMessage = null;
      notifyIfAlive();
    }

    try {
      final favorites = await favoriteApi.fetchMyFavorites();
      if (!_isCurrent(sessionGeneration, refreshGeneration)) return;
      final enriched = await mapBounded(
        favorites,
        enrichmentConcurrency,
        (favorite) => _enrich(FavoriteListItem(favorite: favorite)),
      );
      if (!_isCurrent(sessionGeneration, refreshGeneration)) return;
      items = enriched;
      phase = items.isEmpty ? LoadPhase.empty : LoadPhase.ready;
    } on DioException catch (error) {
      if (!_isCurrent(sessionGeneration, refreshGeneration)) return;
      final code = apiErrorCode(error);
      if (isSessionExpiredCode(code)) {
        await onSessionExpired?.call();
        return;
      }
      if (showLoading) {
        phase = LoadPhase.error;
        // 회원 없음(MEMBER404_1)은 즐겨찾기 없음과 구분해 안내합니다.
        errorMessage = code == 'MEMBER404_1'
            ? '회원 정보를 찾을 수 없습니다.'
            : '즐겨찾기를 불러오지 못했습니다.';
      }
    } catch (_) {
      if (!_isCurrent(sessionGeneration, refreshGeneration)) return;
      if (showLoading) {
        phase = LoadPhase.error;
        errorMessage = '즐겨찾기를 불러오지 못했습니다.';
      }
    } finally {
      if (_isCurrent(sessionGeneration, refreshGeneration)) notifyIfAlive();
    }
  }

  /// 정보를 못 가져온 카드 하나만 TMDB를 다시 조회합니다. 다른 카드는 그대로 둡니다.
  Future<void> retryMovie(int movieId) async {
    final index = items.indexWhere((item) => item.movieId == movieId);
    if (index < 0 || items[index].hasMovie) return;
    final sessionGeneration = sessionGuard.generation;
    final refreshGeneration = _refreshGeneration;
    // 다시 불러오는 동안 오류 문구를 지워 카드가 "불러오는 중"으로 보이게 합니다.
    _replace(movieId, FavoriteListItem(favorite: items[index].favorite));

    final updated = await _enrich(items[index]);
    if (!_isCurrent(sessionGeneration, refreshGeneration)) return;
    _replace(movieId, updated);
  }

  /// 카드 하나의 TMDB 정보를 보충합니다. 실패는 예외가 아니라 카드의 errorMessage로 바꿉니다.
  Future<FavoriteListItem> _enrich(FavoriteListItem item) async {
    final cached = _movieById[item.movieId];
    if (cached != null) {
      return FavoriteListItem(favorite: item.favorite, movie: cached);
    }
    try {
      final movie = await tmdbApi.fetchMovie(item.movieId);
      _movieById[item.movieId] = movie;
      return FavoriteListItem(favorite: item.favorite, movie: movie);
    } catch (_) {
      return FavoriteListItem(
        favorite: item.favorite,
        errorMessage: movieErrorMessage,
      );
    }
  }

  void _replace(int movieId, FavoriteListItem replacement) {
    items = [
      for (final item in items) item.movieId == movieId ? replacement : item,
    ];
    notifyIfAlive();
  }
}
