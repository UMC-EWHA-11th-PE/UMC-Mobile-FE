import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'movie_log_logging_interceptor.dart';

import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

BaseOptions _movieLogOptions() {
  return BaseOptions(
    baseUrl: 'https://workbook.devnoco.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  );
}

Dio createMovieLogClient() {
  final dio = Dio(_movieLogOptions());
  if (kDebugMode) dio.interceptors.add(MovieLogLoggingInterceptor());
  return dio;
}

Dio createAuthMovieLogClient(TokenStorage storage) {
  final dio = Dio(_movieLogOptions());
  dio.interceptors.add(AuthInterceptor(storage));
  if (kDebugMode) dio.interceptors.add(MovieLogLoggingInterceptor());
  return dio;
}
