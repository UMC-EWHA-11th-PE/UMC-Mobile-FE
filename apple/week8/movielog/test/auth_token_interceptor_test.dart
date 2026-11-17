import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/core/network/auth_token_interceptor.dart';

import 'fake_auth.dart';

/// Interceptor를 거친 뒤 실제로 보낼 헤더를 기록하는 Dio를 만듭니다.
Dio _dio(InMemoryTokenStorage storage, List<Map<String, dynamic>> sent) {
  return Dio(BaseOptions(baseUrl: 'http://localhost'))
    ..interceptors.addAll([
      AuthTokenInterceptor(storage),
      InterceptorsWrapper(
        onRequest: (options, handler) {
          sent.add(Map.of(options.headers));
          handler.resolve(Response(requestOptions: options, statusCode: 200));
        },
      ),
    ]);
}

void main() {
  test('보호 요청에만 MovieLog JWT를 Bearer로 붙인다', () async {
    final sent = <Map<String, dynamic>>[];
    final dio = _dio(InMemoryTokenStorage('jwt'), sent);

    await dio.get('/v7/members/me', options: authOptions());
    await dio.post('/v7/auth/login');

    expect(sent[0]['Authorization'], 'Bearer jwt');
    expect(sent[1].containsKey('Authorization'), isFalse);
  });

  test('토큰이 없으면 헤더 없이 보내 서버가 AUTH401_2로 판단하게 둔다', () async {
    final sent = <Map<String, dynamic>>[];
    final dio = _dio(InMemoryTokenStorage(), sent);

    await dio.get('/v7/members/me', options: authOptions());

    expect(sent.single.containsKey('Authorization'), isFalse);
  });
}
