import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_config.dart';

/// 자체 movie 서버 전용 Dio Client를 만듭니다.
/// TMDB와 인증 방식이 달라 `createTmdbClient()`와 따로 둡니다.
/// 경로에 버전(/v5)을 붙이는 것은 각 Service가 담당합니다.
Dio createApiClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'accept': 'application/json'},
    ),
  );

  // 로그는 개발 중 확인용이라 debug 모드에서만 남깁니다.
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        responseBody: true,
        logPrint: (object) => debugPrint('$object'),
      ),
    );
  }

  return dio;
}
