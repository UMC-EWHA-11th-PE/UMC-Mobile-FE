import 'package:dio/dio.dart';

import '../../data/local/token_storage.dart';

/// 보호 요청에 `Authorization: Bearer {MovieLog JWT}`를 붙이는 Interceptor입니다.
///
/// 보호용 MovieLog Client(`createAuthMovieLogClient`)에만 등록합니다.
/// - 공개 요청(로그인·회원가입·중복 확인)을 보내는 Client에는 등록하지 않습니다.
/// - TMDB Client에는 절대 등록하지 않습니다. TMDB에는 TMDB Read Access Token만 보냅니다.
/// - 같은 Client를 거치더라도 명세상 보호 경로가 아니면 토큰을 붙이지 않습니다.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final TokenStorage _storage;

  /// v7 명세에서 인증이 필요한 경로 — 내 정보, 평점 등록·수정·삭제
  bool _isProtected(RequestOptions options) {
    final path = options.uri.path;
    return options.uri.host == 'workbook.devnoco.com' &&
        (path == '/v7/members/me' ||
            path == '/v7/ratings' ||
            path.startsWith('/v7/ratings/'));
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isProtected(options)) {
      handler.next(options);
      return;
    }
    // 이전 요청의 토큰을 재사용하지 않고 매번 저장소에서 다시 읽습니다.
    options.headers.remove('Authorization');
    try {
      final token = await _storage.readAccessToken();
      // 토큰이 없으면 헤더 없이 보내고, 서버가 AUTH401_2로 판단하게 둡니다.
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (_) {
      // 서버 401과 기기 저장소 실패는 다른 오류입니다.
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: StateError('인증 저장소를 읽지 못했습니다.'),
        ),
      );
    }
  }
}
