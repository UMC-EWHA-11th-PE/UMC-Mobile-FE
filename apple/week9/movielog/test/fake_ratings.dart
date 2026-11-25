import 'package:dio/dio.dart';

import 'package:movielog/data/services/rating_api_service.dart';

import 'fake_sign_up.dart';

/// 평점 하나를 v7 응답 모양(JSON)으로 만듭니다. (공개 조회 배열 항목 = 등록·수정 result)
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

/// 공통 오류 하나 — 상태 코드, code, message
typedef FakeApiError = ({int status, String code, String message});

/// 서버 없이 v7 평점 API를 흉내 내는 가짜 서버입니다.
/// - 공개 조회 GET /v8/members/{memberId}/ratings → 직접 배열
/// - 등록 POST /v8/ratings → 201 + result 평점, 수정 PATCH /v8/ratings/{id} → 200 + result 평점
/// - 삭제 DELETE /v8/ratings/{id} → 200 + result null
/// 공개·보호 Client 대신 같은 가짜 Dio 하나를 두 자리에 넣습니다. (토큰 부착은 auth_interceptor_test에서 확인)
///
/// 쓰기가 성공하면 [ratings]를 실제로 바꾸므로, 쓰기 뒤 다시 조회한 결과로 화면을 검증할 수 있습니다.
/// 필드를 테스트 도중 바꿔 "저장은 성공했지만 다시 조회만 실패" 같은 상황을 만들 수 있습니다.
class FakeRatingServer {
  FakeRatingServer({
    List<Map<String, Object?>> ratings = const [],
    List<String>? requests,
  }) : ratings = [...ratings],
       requests = requests ?? [];

  /// 서버에 저장된 평점 (조회 응답 배열 그대로)
  final List<Map<String, Object?>> ratings;

  /// GET 실패 — 상태 코드 응답
  int? getStatusCode;

  /// GET 연결 실패
  bool failGet = false;

  /// 쓰기(POST·PATCH·DELETE) 실패 — 공통 오류 형식 응답
  FakeApiError? writeError;

  /// 이 ratingId에 대한 쓰기만 500 공통 오류로 실패 — 다중 삭제 일부 실패 확인용
  final Set<int> failingRatingIds = {};

  /// 모든 요청을 이 Future가 끝날 때까지 미룸
  Future<void>? gate;

  /// GET 응답을 이만큼 늦춤 — 실제 네트워크처럼 다시 조회하는 동안 화면이 그려지게 합니다.
  Duration getDelay = Duration.zero;

  /// 쓰기 요청만 이 Future가 끝날 때까지 미룸 — 저장 중 상태 확인용
  Future<void>? writeGate;

  /// 보낸 요청 path (메서드 구분 없이)
  final List<String> requests;

  /// 보낸 요청 'METHOD path'
  final List<String> calls = [];

  /// 쓰기 요청 body
  final List<Object?> bodies = [];

  int _nextRatingId = 100;

  late final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080'))
    ..interceptors.add(InterceptorsWrapper(onRequest: _handle));

  late final RatingApiService service = RatingApiService(_dio, _dio);

  Future<void> _handle(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    requests.add(options.path);
    calls.add('${options.method} ${options.path}');
    if (gate != null) await gate;

    DioException badResponse(int status, Object? data) =>
        DioException.badResponse(
          statusCode: status,
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: status,
            data: data,
          ),
        );

    if (options.method == 'GET') {
      if (getDelay > Duration.zero) await Future<void>.delayed(getDelay);
      if (failGet) {
        return handler.reject(
          DioException.connectionError(
            requestOptions: options,
            reason: '테스트용 연결 실패',
          ),
        );
      }
      final status = getStatusCode;
      if (status != null) {
        return handler.reject(
          badResponse(
            status,
            fakeCommonError(
              status == 404 ? 'MEMBER404_1' : 'COMMON$status',
              '테스트용 오류',
            ),
          ),
        );
      }
      return handler.resolve(
        Response(requestOptions: options, statusCode: 200, data: [...ratings]),
      );
    }

    bodies.add(options.data);
    if (writeGate != null) await writeGate;
    final error = writeError;
    if (error != null) {
      return handler.reject(
        badResponse(error.status, fakeCommonError(error.code, error.message)),
      );
    }

    final ratingId = int.tryParse(options.path.split('/').last);
    if (failingRatingIds.contains(ratingId)) {
      return handler.reject(
        badResponse(500, fakeCommonError('COMMON500', '서버 오류')),
      );
    }
    switch (options.method) {
      case 'POST':
        final body = options.data as Map<String, dynamic>;
        final created = fakeRatingJson(
          ratingId: _nextRatingId++,
          movieId: body['movieId'] as int,
          score: body['score'] as int,
          comment: body['comment'] as String?,
        );
        ratings.insert(0, created);
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 201,
            data: {
              'isSuccess': true,
              'code': 'COMMON201',
              'message': '평점을 등록했습니다.',
              'result': created,
            },
          ),
        );
      case 'PATCH':
        final body = options.data as Map<String, dynamic>;
        final index = ratings.indexWhere((r) => r['ratingId'] == ratingId);
        if (index < 0) {
          return handler.reject(
            badResponse(
              404,
              fakeCommonError('RATING404_1', '해당 평점을 찾을 수 없습니다.'),
            ),
          );
        }
        ratings[index] = {
          ...ratings[index],
          'score': body['score'],
          'comment': body['comment'],
        };
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'isSuccess': true,
              'code': 'COMMON200',
              'message': '평점을 수정했습니다.',
              'result': ratings[index],
            },
          ),
        );
      case 'DELETE':
        ratings.removeWhere((r) => r['ratingId'] == ratingId);
        // v7 삭제 성공은 204가 아니라 200 + result null입니다.
        return handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'isSuccess': true,
              'code': 'COMMON200',
              'message': '평점을 삭제했습니다.',
              'result': null,
            },
          ),
        );
    }
  }
}

/// 조회만 필요한 테스트용 간단 버전 — [FakeRatingServer]를 감쌉니다.
///
/// - [ratings]를 배열 그대로 응답 (기본값은 빈 배열)
/// - [statusCode]가 있으면 공통 오류 형식으로 그 상태 코드 응답 (400·404 등)
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
  final server = FakeRatingServer(ratings: ratings, requests: requests)
    ..getStatusCode = statusCode
    ..failGet = fail
    ..gate = gate;
  return server.service;
}
