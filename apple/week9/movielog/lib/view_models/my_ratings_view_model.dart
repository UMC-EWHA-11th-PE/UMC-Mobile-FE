import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../data/models/tmdb_movie_detail_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'session_rating_store.dart';
import 'submit_status.dart';

export 'submit_status.dart';

enum MyRatingsLoadStatus { idle, loading, success, empty, error }

/// 내가 등록한 평점 화면의 상태 — 자체 서버 평점 목록에 TMDB 영화 정보를 붙입니다.
///
/// - 평점 조회가 실패하면 error, 결과가 없으면 empty입니다.
/// - TMDB 영화 조회가 실패해도 평점은 그대로 두고 영화 정보만 비웁니다.
/// - 같은 movieId는 한 번만 조회해 캐시합니다. 일시적인 실패는 캐시하지 않아 다음 로딩에서 다시 시도합니다.
/// - 화면을 벗어났거나 새 요청이 시작된 뒤 도착한 이전 응답은 무시합니다.
///
/// 8주차(v7) — 목록은 두 곳을 합칩니다.
/// - 이번 로그인 세션에서 등록·수정한 평점 ([SessionRatingStore], 등록·수정 응답의 평점 객체)
/// - [memberId]가 있으면 공개 조회 GET /v8/members/{memberId}/ratings (토큰 없음)
///   memberId는 이 앱에서 가입한 계정과 같은 email로 로그인했을 때만 받습니다.
/// memberId가 없으면 이번 세션 등록분만 보여주고 [sessionOnlyNotice]로 안내합니다.
/// 수정·삭제는 JWT로 보내고 memberId를 쓰지 않습니다. 소유자 확인은 서버가 토큰으로 합니다.
///
/// 7주차 — 수정·삭제가 성공하면 목록을 다시 조회합니다.
/// - 쓰기 실패: [WriteFailure]를 던져 Dialog가 실패로 처리 (입력 유지, 다시 시도)
/// - 쓰기 성공 + 재조회 실패: 저장 성공으로 돌려주고 [refreshWarning]으로 조회만 다시 시도하게 안내
/// - 401(AUTH401_2/3/4): [onSessionExpired]로 세션 정리 → Router가 /login으로 이동
/// - 403(RATING403_1)·404(RATING404_1): 안내 후 목록을 다시 맞춥니다. 로그아웃하지 않습니다.
///
/// W7-CH 다중 삭제 — 선택 모드에서 고른 평점을 하나씩 DELETE한 뒤 목록을 한 번만 다시 조회합니다.
/// 삭제 중에는 [isBulkDeleting]으로 화면 전체 입력을 막습니다.
class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(
    this._service,
    this._movieService, {
    this.memberId,
    SessionRatingStore? sessionRatings,
    this.sessionVersion = 0,
    this.onSessionExpired,
  }) : _sessionRatings = sessionRatings ?? SessionRatingStore();

  final RatingApiService _service;
  final TmdbMovieService _movieService;
  final SessionRatingStore _sessionRatings;

  /// 공개 조회에 쓸 내 memberId — 이 앱에서 가입한 같은 계정이 아니면 null
  final int? memberId;

  /// 이 화면을 연 로그인 세션 — 다른 세션의 등록분을 섞지 않습니다.
  final int sessionVersion;

  /// 보호 요청이 세션 만료(AUTH401_2/3/4)를 받았을 때 세션 정리를 요청합니다.
  final Future<void> Function()? onSessionExpired;

  /// 이 화면은 로그인해야 열리고 목록은 내 평점만 담으므로 수정·삭제 버튼을 보여줍니다.
  /// 실제 소유자 확인은 서버가 토큰으로 하며, 아니면 RATING403_1로 거절합니다.
  bool get canModify => true;

  /// 공개 조회를 못 하고 이번 세션 등록분만 보여줄 때의 안내
  String? get sessionOnlyNotice => memberId == null
      ? '이번 로그인에서 등록한 평점만 보여요.\n이전에 남긴 평점은 아직 불러올 수 없어요.'
      : null;

  /// 저장은 성공했지만 다시 조회가 실패했을 때의 안내 — 다음 조회가 성공하면 지웁니다.
  String? refreshWarning;

  /// movieId → TMDB 영화 (404로 없는 영화면 null을 저장)
  final Map<int, TmdbMovieDetailDto?> _movieCache = {};
  int _requestVersion = 0;
  bool _disposed = false;

  List<RatingWithMovie> ratings = const [];
  MyRatingsLoadStatus status = MyRatingsLoadStatus.idle;

  /// error면 실패 안내, success면 일부 영화 정보를 못 찾았다는 안내 (없으면 null)
  String? message;

  static const _loadFailedText = '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
  static const _missingMoviesText = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';

  Future<void> load() async {
    final version = ++_requestVersion;
    status = MyRatingsLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final id = memberId;
      final fromServer = id == null
          ? const <RatingDto>[]
          : await _service.fetchMyRatings(id);
      if (_disposed || version != _requestVersion) return;

      // 서버 목록을 기준으로, 아직 서버 목록에 없는 이번 세션 등록분을 앞에 붙입니다.
      final serverIds = {for (final rating in fromServer) rating.ratingId};
      final rawRatings = [
        for (final rating in _sessionRatings.ratings(sessionVersion))
          if (!serverIds.contains(rating.ratingId)) rating,
        ...fromServer,
      ];

      // 캐시에 없는 영화만 한꺼번에 조회합니다. 하나가 실패해도 나머지 평점은 지우지 않습니다.
      final uncachedIds = {
        for (final rating in rawRatings)
          if (!_movieCache.containsKey(rating.movieId)) rating.movieId,
      };
      await Future.wait(uncachedIds.map(_cacheMovie));
      if (_disposed || version != _requestVersion) return;

      final entries = [
        for (final rating in rawRatings)
          RatingWithMovie(rating: rating, movie: _movieCache[rating.movieId]),
      ];
      ratings = entries;
      refreshWarning = null;
      status = entries.isEmpty
          ? MyRatingsLoadStatus.empty
          : MyRatingsLoadStatus.success;
      if (entries.any((entry) => entry.movie == null)) {
        message = _missingMoviesText;
      }
    } on DioException catch (error) {
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = writeMyRatingsErrorMessage(error);
    } catch (_) {
      // 응답 모양이 예상과 달라도 loading에 멈추지 않도록 error로 바꿉니다.
      if (_disposed || version != _requestVersion) return;
      status = MyRatingsLoadStatus.error;
      message = _loadFailedText;
    }
    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 다중 삭제 (W7-CH)
  // ---------------------------------------------------------------------------

  bool _isSelecting = false;
  bool get isSelecting => _isSelecting;

  final Set<int> _selectedIds = {};
  Set<int> get selectedIds => Set.unmodifiable(_selectedIds);

  /// 다중 삭제 요청 중 — 화면은 전체를 덮는 로딩으로 터치·뒤로가기를 막습니다.
  bool isBulkDeleting = false;

  /// 길게 누른 평점을 선택한 채로 선택 모드를 시작합니다.
  void startSelection(int ratingId) {
    if (!canModify || isBulkDeleting) return;
    _isSelecting = true;
    _selectedIds
      ..clear()
      ..add(ratingId);
    notifyListeners();
  }

  void toggleSelection(int ratingId) {
    if (!_isSelecting || isBulkDeleting) return;
    if (!_selectedIds.remove(ratingId)) _selectedIds.add(ratingId);
    notifyListeners();
  }

  void cancelSelection() {
    if (isBulkDeleting) return;
    _isSelecting = false;
    _selectedIds.clear();
    notifyListeners();
  }

  /// 선택한 평점을 순서대로 삭제하고 실패한 개수를 돌려줍니다.
  ///
  /// v7에도 여러 개를 한 번에 지우는 API가 없어 DELETE /v8/ratings/{id}를 하나씩 보냅니다.
  /// - 모두 성공: 선택 모드를 끝냅니다.
  /// - 일부 실패: 실패한 평점만 선택된 채로 남겨 다시 시도할 수 있게 합니다.
  /// - 한 개라도 서버 상태가 바뀌었으면 목록을 한 번만 다시 조회합니다.
  Future<int> deleteSelected() async {
    if (isBulkDeleting || _selectedIds.isEmpty) return 0;
    isBulkDeleting = true;
    notifyListeners();

    final failedIds = <int>{};
    var needsRefresh = false;
    for (final ratingId in [..._selectedIds]) {
      try {
        await _service.deleteRating(ratingId);
        _sessionRatings.remove(sessionVersion, ratingId);
        needsRefresh = true;
      } on DioException catch (error) {
        if (isSessionExpiredCode(apiErrorCode(error))) {
          // 세션 만료: 남은 삭제는 보내지 않고 정리합니다. Router가 /login으로 보냅니다.
          isBulkDeleting = false;
          await onSessionExpired?.call();
          return _selectedIds.length;
        }
        failedIds.add(ratingId);
        if (shouldRefreshAfterRatingError(error)) {
          // 이미 없는 평점(404)은 이번 세션 보관분에서도 뺍니다.
          if (apiErrorCode(error) == 'RATING404_1') {
            _sessionRatings.remove(sessionVersion, ratingId);
          }
          needsRefresh = true;
        }
      } catch (_) {
        failedIds.add(ratingId);
      }
      if (_disposed) return failedIds.length;
    }

    if (needsRefresh) await _refreshAfterWrite();
    if (_disposed) return failedIds.length;

    // 다시 조회한 목록에 남아 있는 실패 평점만 선택 상태로 둡니다.
    final remaining = {for (final entry in ratings) entry.rating.ratingId};
    _selectedIds
      ..clear()
      ..addAll(failedIds.where(remaining.contains));
    _isSelecting = _selectedIds.isNotEmpty;
    isBulkDeleting = false;
    notifyListeners();
    return failedIds.length;
  }

  /// 평점 수정 — PATCH /v8/ratings/{ratingId}. 전체 교체라 comment가 null이면 후기를 지웁니다.
  /// 성공 result(수정된 평점)로 이번 세션 보관분을 바꿉니다.
  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) {
    return _write(ratingId, () async {
      final updated = await _service.updateRating(
        ratingId: ratingId,
        score: score,
        comment: comment,
      );
      _sessionRatings.upsert(sessionVersion, updated);
    });
  }

  /// 평점 삭제 — DELETE /v8/ratings/{ratingId} (200, result null)
  Future<void> deleteRating(int ratingId) {
    return _write(ratingId, () async {
      await _service.deleteRating(ratingId);
      _sessionRatings.remove(sessionVersion, ratingId);
    });
  }

  /// 쓰기 → 성공하면 다시 조회. 쓰기 실패와 재조회 실패를 구분합니다.
  Future<void> _write(int ratingId, Future<void> Function() request) async {
    try {
      await request();
    } on DioException catch (error) {
      final code = apiErrorCode(error);
      if (isSessionExpiredCode(code)) {
        // 세션 만료: 정리하면 Router가 로그인 화면으로 보내고 그곳에서 안내합니다.
        await onSessionExpired?.call();
        throw const WriteFailure('로그인이 만료됐어요. 다시 로그인해 주세요.');
      }
      // 403(본인 평점 아님)·404(이미 없는 평점)는 화면 목록이 서버와 어긋났다는 뜻 — 다시 맞춥니다.
      if (shouldRefreshAfterRatingError(error) && !_disposed) {
        if (code == 'RATING404_1') {
          _sessionRatings.remove(sessionVersion, ratingId);
        }
        await load();
      }
      throw WriteFailure(writeErrorMessage(error));
    } catch (_) {
      throw const WriteFailure('저장하지 못했습니다. 잠시 후 다시 시도해 주세요.');
    }
    // 여기부터는 저장 성공 — GET이 실패해도 저장 실패로 다시 던지지 않습니다.
    if (!_disposed) await _refreshAfterWrite();
  }

  Future<void> _refreshAfterWrite() async {
    await load(); // 실패하면 load()가 status=error로 기록합니다.
    if (_disposed) return;
    if (status == MyRatingsLoadStatus.error) {
      refreshWarning = '저장은 완료됐지만 목록을 불러오지 못했습니다.\n조회만 다시 시도해 주세요.';
      notifyListeners();
    }
  }

  /// TMDB에서 영화를 찾아 캐시에 넣습니다. 없는 영화(404)는 null로 캐시하고,
  /// 그 밖의 실패는 캐시하지 않아 다음 로딩에서 다시 시도합니다.
  Future<void> _cacheMovie(int movieId) async {
    try {
      _movieCache[movieId] = await _movieService.findMovieById(movieId);
    } catch (_) {
      // 영화 정보만 placeholder로 표시합니다.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
