import 'package:dio/dio.dart';

import '../../data/local/auth_token_storage.dart';

/// 보호 요청 표시 — `Options(extra: {requiresAuthKey: true})`를 단 요청에만 JWT를 붙입니다.
const requiresAuthKey = 'requiresAuth';

/// MovieLog 보호 요청(`/members/me`, 평점 쓰기 등)에 쓰는 Options입니다.
Options authOptions() => Options(extra: const {requiresAuthKey: true});

/// MovieLog Dio에만 붙이는 Interceptor — 보호 요청에 `Authorization: Bearer {MovieLog JWT}`를 넣습니다.
///
/// - 로그인·회원가입·중복 확인 같은 공개 요청에는 붙이지 않습니다.
/// - TMDB Client에는 절대 붙이지 않습니다. TMDB에는 TMDB Read Access Token만 보냅니다.
/// - 토큰이 없으면 헤더 없이 보내고, 서버가 AUTH401_2로 판단하게 둡니다.
class AuthTokenInterceptor extends Interceptor {
  AuthTokenInterceptor(this._storage);

  final AuthTokenStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[requiresAuthKey] != true) return handler.next(options);

    try {
      final token = await _storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (error) {
      // 저장소를 읽지 못하면 보내지 않고 요청 실패로 넘깁니다.
      handler.reject(DioException(requestOptions: options, error: error));
    }
  }
}
