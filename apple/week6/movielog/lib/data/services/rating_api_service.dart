import 'package:dio/dio.dart';

import '../models/rating_dto.dart';

/// v5 유저별 평점 조회 API(GET /v5/members/{memberId}/ratings)를 호출합니다.
///
/// v5는 공통 Wrapper가 없어 응답 body가 평점 배열 그대로입니다.
/// 실패(400·404·통신 오류)는 DioException으로 ViewModel에 넘깁니다.
class RatingApiService {
  RatingApiService(this._dio);

  final Dio _dio;

  /// 평점이 하나도 없으면 빈 목록을 돌려줍니다.
  Future<List<RatingDto>> fetchMyRatings(int memberId) async {
    final response = await _dio.get('/v5/members/$memberId/ratings');
    final list = response.data as List<dynamic>;
    return list
        .map((item) => RatingDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

/// 평점 조회 실패를 상태 코드별 안내 문구로 바꿉니다.
/// - 400: memberId 형식 오류
/// - 404: 존재하지 않는 유저
/// - 그 외(통신 실패, 5xx 등): 잠시 후 다시 시도
String writeMyRatingsErrorMessage(DioException error) {
  final status = error.response?.statusCode;
  if (status == 400) return 'memberId 형식을 다시 확인해 주세요.';
  if (status == 404) return '존재하지 않는 회원입니다.';
  return '평점을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.';
}
