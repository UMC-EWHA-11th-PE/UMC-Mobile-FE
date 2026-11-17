import 'package:dio/dio.dart';

import '../../core/network/api_error.dart';
import '../models/common_response.dart';
import '../models/rating_dto.dart';
import '../models/rating_request.dart';

/// 공통 응답을 한 번 파싱하고 `result`에서 평점 하나를 꺼냅니다. (v7 등록·수정 성공)
RatingDto parseRatingResult(Object? data) {
  if (data is! Map<String, dynamic>) {
    throw StateError('평점 응답 형식이 올바르지 않습니다.');
  }
  final common = CommonResponse<RatingDto>.fromJson(
    data,
    (value) => RatingDto.fromJson(value as Map<String, dynamic>),
  );
  final rating = common.result;
  if (rating == null) throw StateError('평점 result가 없습니다.');
  return rating;
}

/// 유저별 평점 조회 성공은 공통 형식으로 감싸지 않은 배열 그대로입니다.
List<RatingDto> parseRatingList(Object? data) {
  if (data is! List) throw StateError('평점 목록 응답은 배열이어야 합니다.');
  return data
      .map((value) => RatingDto.fromJson(value as Map<String, dynamic>))
      .toList();
}

/// v7 평점 API를 호출합니다. 메서드마다 보낼 Client를 Service가 정합니다.
///
/// | 동작 | 요청                                     | Client | 성공                         |
/// | ---- | ---------------------------------------- | ------ | ---------------------------- |
/// | 조회 | GET    /v7/members/{memberId}/ratings    | 공개   | 200 + 직접 배열 (ratingId 내림차순) |
/// | 등록 | POST   /v7/ratings                       | 보호   | 201 + 공통 형식, result = 평점 |
/// | 수정 | PATCH  /v7/ratings/{ratingId}            | 보호   | 200 + 공통 형식, result = 평점 |
/// | 삭제 | DELETE /v7/ratings/{ratingId}            | 보호   | 200 + 공통 형식, result null |
///
/// 쓰기에는 memberId가 없습니다. 서버가 JWT로 현재 회원을 식별합니다.
/// 실패는 DioException 그대로 ViewModel로 넘깁니다.
class RatingApiService {
  RatingApiService(this._publicDio, this._authDio);

  /// Interceptor 없음 — 토큰이 실리지 않는 공개 조회용
  final Dio _publicDio;

  /// AuthInterceptor 등록 — 요청마다 MovieLog JWT를 붙이는 보호 요청용
  final Dio _authDio;

  /// 공개 조회 — 평점이 하나도 없으면 빈 목록입니다.
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _publicDio.get('/v7/members/$memberId/ratings');
    return parseRatingList(response.data);
  }

  /// 평점 등록 — 성공 result가 등록된 평점 객체입니다.
  Future<RatingDto> createRating(CreateRatingRequest request) async {
    final response = await _authDio.post('/v7/ratings', data: request.toJson());
    return parseRatingResult(response.data);
  }

  /// 평점 수정 — PATCH지만 전체 교체입니다. comment를 생략하면 기존 후기가 null로 덮이므로
  /// Dialog에 기존 score·comment를 채워 두고 항상 두 값을 함께 보냅니다.
  Future<RatingDto> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    final response = await _authDio.patch(
      '/v7/ratings/$ratingId',
      data: UpdateRatingRequest(score: score, comment: comment).toJson(),
    );
    return parseRatingResult(response.data);
  }

  /// 평점 삭제 — v6의 204(body 없음)와 달리 200 + result null입니다.
  Future<void> deleteRating(int ratingId) async {
    final response = await _authDio.delete('/v7/ratings/$ratingId');
    if (response.statusCode != 200) {
      throw StateError('예상하지 못한 삭제 응답: ${response.statusCode}');
    }
  }
}

/// 평점 조회 실패 안내 — 공개 조회의 회원 없음은 MEMBER404_1입니다.
String writeMyRatingsErrorMessage(DioException error) {
  if (apiErrorCode(error) == 'MEMBER404_1') return '해당 회원을 찾을 수 없습니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 평점 쓰기(등록·수정·삭제) 실패 문구 — 서버 `message`를 그대로 씁니다.
///
/// RATING409_1(이미 평점을 남긴 영화)은 기존 기록을 확인하도록 안내합니다.
String writeErrorMessage(DioException error) {
  if (apiErrorCode(error) == 'RATING409_1') {
    return '이미 평점을 남긴 영화예요. 내가 등록한 평점에서 확인해 주세요.';
  }
  return apiErrorMessage(error) ?? '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.';
}

/// 쓰기 실패 뒤 목록을 다시 조회할지 정합니다. code는 문구가 아니라 다음 UI 행동에만 씁니다.
///
/// - RATING403_1(본인 평점 아님)·RATING404_1(없는 평점): 화면 목록이 서버와 어긋났으므로 다시 조회
/// - COMMON400(별점 범위)·RATING409_1(중복 등록): 값만 고쳐 다시 시도하면 되므로 다시 조회하지 않음
/// - 403은 권한 부족이지 로그인 만료가 아니므로 로그아웃하지 않습니다.
bool shouldRefreshAfterRatingError(DioException error) {
  final code = apiErrorCode(error);
  return code == 'RATING403_1' || code == 'RATING404_1';
}
