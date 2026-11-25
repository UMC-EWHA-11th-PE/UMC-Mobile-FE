import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/local/token_storage.dart';
import 'auth_interceptor.dart';

/// 워크북 자체 백엔드 Client 공통 설정입니다.
///
/// TMDB와 baseUrl·헤더가 달라 `createTmdbClient()`와 절대 합치지 않습니다.
/// 경로에 버전(/v7)을 붙이는 것은 각 Service가 담당합니다.
BaseOptions _movieLogOptions() {
  return BaseOptions(
    baseUrl: 'https://workbook.devnoco.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );
}

/// 공개 요청용 (6주차 Client 유지): 로그인, 회원가입, 중복 체크, 유저별 평점 조회
/// AuthInterceptor를 등록하지 않으므로 JWT가 실리지 않습니다.
Dio createMovieLogClient() {
  final dio = Dio(_movieLogOptions());
  _addDebugLog(dio);
  return dio;
}

/// 보호 요청용 (8주차 추가): 내 정보, 평점 등록·수정·삭제
/// AuthInterceptor가 요청마다 TokenStorage에서 JWT를 읽어 붙입니다.
Dio createAuthMovieLogClient(TokenStorage storage) {
  final dio = Dio(_movieLogOptions());
  dio.interceptors.add(AuthInterceptor(storage));
  _addDebugLog(dio);
  return dio;
}

/// 로그는 개발 중 확인용이라 debug 모드에서만 남깁니다.
///
/// - 요청 헤더(Authorization)와 요청 body(비밀번호)는 남기지 않습니다.
/// - 응답 body는 오류 code·message 확인에 필요해 남기되,
///   로그인 응답의 accessToken 같은 JWT 문자열은 [redactTokens]로 가립니다.
void _addDebugLog(Dio dio) {
  if (!kDebugMode) return;
  dio.interceptors.add(
    LogInterceptor(
      requestHeader: false,
      requestBody: false,
      responseBody: true,
      logPrint: (object) => debugPrint(redactTokens('$object')),
    ),
  );
}

final _accessTokenField = RegExp(
  r'''(accessToken["']?\s*[:=]\s*)(?:"[^"]*"|'[^']*'|[^,}\s]+)''',
);
final _jwt = RegExp(r'eyJ[\w-]*\.[\w-]*\.[\w-]*');

/// 로그 문자열에서 accessToken 값과 JWT 형태의 문자열을 `***`로 바꿉니다.
String redactTokens(String text) {
  return text
      .replaceAllMapped(_accessTokenField, (match) => '${match[1]}***')
      .replaceAll(_jwt, '***');
}
