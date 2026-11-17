import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/rating_dto.dart';
import '../data/models/rating_request.dart';
import '../data/services/rating_api_service.dart';
import 'auth_view_model.dart';

/// 현재 로그인 세션에서 등록한 평점을 movieId별로 보관합니다.
///
/// v7에는 토큰 기반 "내 평점 목록 GET"이 없고 로그인/내 정보 응답에 memberId도 없습니다.
/// 그래서 워크북 안내대로 "등록 response로 받은 Rating"을 현재 세션에서만
/// 수정·삭제합니다. 앱 재시작 뒤 기존 평점 복원은 지원하지 않습니다(API 한계).
class SessionRatingsViewModel extends ChangeNotifier {
  SessionRatingsViewModel(this._service, this._auth)
      : _version = _auth.sessionVersion {
    _auth.addListener(_onAuthChanged);
  }

  final RatingApiService _service;
  final AuthViewModel _auth;
  final Map<int, RatingDto> _byMovieId = {};
  int _version;
  bool _disposed = false;

  RatingDto? ratingFor(int movieId) => _byMovieId[movieId];

  List<RatingDto> get ratings => _byMovieId.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// 로그아웃·만료·다른 계정 로그인 시 이전 세션의 평점을 비웁니다.
  void _onAuthChanged() {
    if (_auth.sessionVersion == _version) return;
    _version = _auth.sessionVersion;
    if (_byMovieId.isEmpty) return;
    _byMovieId.clear();
    _notify();
  }

  Future<void> createRating({
    required int movieId,
    required int score,
    String? comment,
  }) async {
    final version = _requireSignedIn();
    try {
      final created = await _service.createRating(
        CreateRatingRequest(movieId: movieId, score: score, comment: comment),
      );
      if (!_isCurrent(version)) return; // 세션이 바뀌었으면 반영하지 않습니다.
      _byMovieId[created.movieId] = created; // 등록 result(Rating)로 카드 갱신
      _notify();
    } on DioException catch (error) {
      throw await _toUserMessage(error, version);
    }
  }

  Future<void> updateRating({
    required RatingDto rating,
    required int score,
    String? comment,
  }) async {
    final version = _requireSignedIn();
    try {
      final updated = await _service.updateRating(
        ratingId: rating.ratingId,
        score: score,
        comment: comment, // 비웠다면 null → 기존 후기 삭제 의도
      );
      if (!_isCurrent(version)) return;
      _byMovieId[updated.movieId] = updated;
      _notify();
    } on DioException catch (error) {
      if (apiErrorCode(error) == 'RATING404_1') _remove(rating.movieId);
      throw await _toUserMessage(error, version);
    }
  }

  Future<void> deleteRating(RatingDto rating) async {
    final version = _requireSignedIn();
    try {
      await _service.deleteRating(rating.ratingId);
      if (!_isCurrent(version)) return;
      _remove(rating.movieId);
    } on DioException catch (error) {
      if (apiErrorCode(error) == 'RATING404_1') _remove(rating.movieId);
      throw await _toUserMessage(error, version);
    }
  }

  int _requireSignedIn() {
    if (_auth.status != AuthStatus.signedIn) {
      throw const UserMessageException('로그인이 필요해요.');
    }
    return _auth.sessionVersion;
  }

  bool _isCurrent(int version) =>
      !_disposed && version == _auth.sessionVersion;

  void _remove(int movieId) {
    if (_byMovieId.remove(movieId) != null) _notify();
  }

  /// 오류 code별로 다음 행동을 정하고, 화면에 보여줄 문구를 돌려줍니다.
  /// - 401(AUTH401_2/3/4): 세션 정리 → Router가 /login으로 이동
  /// - 403·409: 안내만 하고 로그인 상태 유지
  Future<UserMessageException> _toUserMessage(
    DioException error,
    int version,
  ) async {
    if (isSessionExpiredError(error)) {
      if (_isCurrent(version)) await _auth.expireSession();
      return const UserMessageException('로그인이 만료됐어요. 다시 로그인해 주세요.');
    }
    final message = switch (apiErrorCode(error)) {
      'RATING403_1' => '본인이 작성한 평점만 수정하거나 삭제할 수 있어요.',
      'RATING409_1' => '이미 이 영화에 평점을 남겼어요.',
      'RATING404_1' => '이미 삭제되었거나 존재하지 않는 평점이에요.',
      'COMMON400' => apiErrorMessage(error) ?? '입력값을 확인해 주세요.',
      _ => '요청에 실패했어요. 잠시 후 다시 시도해 주세요.',
    };
    return UserMessageException(message);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
