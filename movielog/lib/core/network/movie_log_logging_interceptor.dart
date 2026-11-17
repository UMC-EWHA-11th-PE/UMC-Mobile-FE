import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class MovieLogLoggingInterceptor extends Interceptor {
  Object? _maskBody(Object? data) {
    if (data is Map) {
      return data.map(
        (k, v) => MapEntry(
          k,
          (k == 'password' || k == 'accessToken') ? '***' : _maskBody(v),
        ),
      );
    }
    return data;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final hasAuth = options.headers.containsKey('Authorization');
    debugPrint(
      '[MovieLog 요청] ${options.method} ${options.uri.path}'
      ' / Authorization: ${hasAuth ? 'Bearer ***' : '없음'}',
    );
    if (options.data != null)
      debugPrint('[MovieLog 요청 Body] ${_maskBody(options.data)}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '[MovieLog 응답] ${response.statusCode} ${response.requestOptions.uri.path}',
    );
    debugPrint('[MovieLog 응답 Body] ${_maskBody(response.data)}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '[MovieLog 오류] ${err.response?.statusCode} ${err.requestOptions.uri.path}',
    );
    debugPrint('[MovieLog 오류 Body] ${_maskBody(err.response?.data)}');
    handler.next(err);
  }
}
