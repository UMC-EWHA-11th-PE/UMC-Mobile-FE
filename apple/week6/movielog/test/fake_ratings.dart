import 'package:dio/dio.dart';

import 'package:movielog/data/services/rating_api_service.dart';

/// 평점 하나를 v5 응답 모양(JSON)으로 만듭니다.
Map<String, Object?> fakeRatingJson({
  int ratingId = 12,
  int movieId = 550,
  int score = 5,
  String? comment = '최고의 영화!',
  String createdAt = '2026-09-06T12:14:03.000Z',
}) => {
  'ratingId': ratingId,
  'movieId': movieId,
  'score': score,
  'comment': comment,
  'createdAt': createdAt,
  'updatedAt': createdAt,
};

/// 서버 없이 v5 유저별 평점 조회 응답을 흉내 내는 [RatingApiService]를 만듭니다.
///
/// - [ratings]를 배열 그대로 응답 (기본값은 빈 배열)
/// - [statusCode]가 있으면 프레임워크 기본 오류 형식으로 그 상태 코드 응답 (400·404 등)
/// - [fail]이 true면 연결 오류(DioException)
/// - [gate]가 있으면 그 Future가 끝날 때까지 응답을 미룸 — Loading 상태 확인용
/// - [requests]에 보낸 요청 path를 순서대로 기록
RatingApiService fakeRatingApiService({
  List<Map<String, Object?>> ratings = const [],
  int? statusCode,
  bool fail = false,
  Future<void>? gate,
  List<String>? requests,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          requests?.add(options.path);
          if (gate != null) await gate;

          if (fail) {
            return handler.reject(
              DioException.connectionError(
                requestOptions: options,
                reason: '테스트용 연결 실패',
              ),
            );
          }

          if (statusCode != null) {
            return handler.reject(
              DioException.badResponse(
                statusCode: statusCode,
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: statusCode,
                  data: {
                    'message': '테스트용 오류',
                    'error': 'Error',
                    'statusCode': statusCode,
                  },
                ),
              ),
            );
          }

          handler.resolve(
            Response(requestOptions: options, statusCode: 200, data: ratings),
          );
        },
      ),
    );
  return RatingApiService(dio);
}
