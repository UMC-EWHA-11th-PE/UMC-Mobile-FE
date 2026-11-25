import 'package:dio/dio.dart';

import 'package:movielog/data/services/favorite_api_service.dart';

import 'fake_sign_up.dart' show fakeCommonError;

/// 서버 없이 v8 즐겨찾기 API를 흉내 내는 가짜 서버입니다.
/// - POST   /v8/favorites            → 201 + result FavoriteResponseDto (이미 있으면 409 FAVORITE409_1)
/// - GET    /v8/favorites            → 200 + result 배열
/// - GET    /v8/favorites/{movieId}  → 200 + result { isFavorite }
/// - DELETE /v8/favorites/{movieId}  → 200 + result null (없으면 404 FAVORITE404_1)
///
/// 성공한 쓰기는 [movieIds]를 실제로 바꿉니다. 토큰 부착은 auth_interceptor_test에서 확인합니다.
class FakeFavoriteServer {
  FakeFavoriteServer({List<int> movieIds = const []})
    : movieIds = [...movieIds];

  /// 서버에 저장된 즐겨찾기 movieId (등록 순서)
  final List<int> movieIds;

  /// 다음 요청 하나를 이 오류로 실패시킵니다. (status, code) — 사용 후 비웁니다.
  ({int status, String code})? nextError;

  /// 이 메서드('GET'·'POST'·'DELETE') 요청을 연결 실패로 만듭니다.
  final Set<String> failMethods = {};

  /// 모든 요청을 이 Future가 끝날 때까지 미룸 — 요청 중 상태 확인용
  Future<void>? gate;

  /// 보낸 요청 'METHOD path'
  final List<String> calls = [];

  late final Dio _dio = Dio(
    BaseOptions(baseUrl: 'https://workbook.devnoco.com'),
  )..interceptors.add(InterceptorsWrapper(onRequest: _handle));

  late final FavoriteApiService service = FavoriteApiService(_dio);

  Map<String, Object?> _favoriteJson(int movieId) => {
    'favoriteId': movieIds.indexOf(movieId) + 1,
    'movieId': movieId,
    'createdAt': '2026-09-06T12:14:03.000Z',
  };

  Map<String, Object?> _ok(String code, Object? result) => {
    'isSuccess': true,
    'code': code,
    'message': 'ok',
    'result': result,
  };

  Future<void> _handle(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final method = options.method.toUpperCase();
    calls.add('$method ${options.path}');
    if (gate != null) await gate;

    DioException bad(int status, String code) => DioException.badResponse(
      statusCode: status,
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: status,
        data: fakeCommonError(code, 'server message for $code'),
      ),
    );

    if (failMethods.contains(method)) {
      return handler.reject(
        DioException.connectionError(
          requestOptions: options,
          reason: '테스트용 연결 실패',
        ),
      );
    }
    final forced = nextError;
    if (forced != null) {
      nextError = null;
      return handler.reject(bad(forced.status, forced.code));
    }

    Response<Object?> ok(int status, Object? data) =>
        Response(requestOptions: options, statusCode: status, data: data);

    final idMatch = RegExp(r'^/v8/favorites/(\d+)$').firstMatch(options.path);
    if (options.path == '/v8/favorites' && method == 'GET') {
      return handler.resolve(
        ok(
          200,
          _ok('COMMON200', [for (final id in movieIds) _favoriteJson(id)]),
        ),
      );
    }
    if (options.path == '/v8/favorites' && method == 'POST') {
      final movieId = (options.data as Map)['movieId'] as int;
      if (movieIds.contains(movieId)) {
        return handler.reject(bad(409, 'FAVORITE409_1'));
      }
      movieIds.add(movieId);
      return handler.resolve(ok(201, _ok('COMMON201', _favoriteJson(movieId))));
    }
    if (idMatch != null) {
      final movieId = int.parse(idMatch.group(1)!);
      if (method == 'GET') {
        return handler.resolve(
          ok(200, _ok('COMMON200', {'isFavorite': movieIds.contains(movieId)})),
        );
      }
      if (method == 'DELETE') {
        if (!movieIds.remove(movieId)) {
          return handler.reject(bad(404, 'FAVORITE404_1'));
        }
        return handler.resolve(ok(200, _ok('COMMON200', null)));
      }
    }
    handler.reject(bad(404, 'COMMON404'));
  }
}
