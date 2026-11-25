import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/network/movie_log_client.dart';

import 'fake_auth.dart';

/// AuthInterceptor를 거친 뒤 실제로 보낼 헤더를 기록하는 Dio를 만듭니다.
Dio _dio(
  InMemoryTokenStorage storage,
  List<Map<String, dynamic>> sent, {
  String baseUrl = 'https://workbook.devnoco.com',
}) {
  return Dio(BaseOptions(baseUrl: baseUrl))
    ..interceptors.addAll([
      AuthInterceptor(storage),
      InterceptorsWrapper(
        onRequest: (options, handler) {
          sent.add(Map.of(options.headers));
          handler.resolve(Response(requestOptions: options, statusCode: 200));
        },
      ),
    ]);
}

void main() {
  group('AuthInterceptor', () {
    test('내 정보·평점 등록/수정/삭제에는 MovieLog JWT를 Bearer로 붙인다', () async {
      final sent = <Map<String, dynamic>>[];
      final dio = _dio(InMemoryTokenStorage('jwt'), sent);

      await dio.get('/v8/members/me');
      await dio.post('/v8/ratings');
      await dio.patch('/v8/ratings/3');
      await dio.delete('/v8/ratings/3');

      expect(sent.map((h) => h['Authorization']), everyElement('Bearer jwt'));
    });

    test('로그인·중복 확인·유저별 평점 조회 같은 공개 경로에는 붙이지 않는다', () async {
      final sent = <Map<String, dynamic>>[];
      final dio = _dio(InMemoryTokenStorage('jwt'), sent);

      await dio.post('/v8/auth/login');
      await dio.get('/v8/members/email/a%40b.com');
      await dio.get('/v8/members/1/ratings');

      for (final headers in sent) {
        expect(headers.containsKey('Authorization'), isFalse);
      }
    });

    test('워크북 서버가 아닌 host(TMDB 등)에는 붙이지 않는다', () async {
      final sent = <Map<String, dynamic>>[];
      final dio = _dio(
        InMemoryTokenStorage('jwt'),
        sent,
        baseUrl: 'https://api.themoviedb.org',
      );

      await dio.get('/v8/members/me');

      expect(sent.single.containsKey('Authorization'), isFalse);
    });

    test('이전 Authorization을 지우고 저장소의 현재 토큰만 쓴다', () async {
      final sent = <Map<String, dynamic>>[];
      final storage = InMemoryTokenStorage();
      final dio = _dio(storage, sent);

      // 토큰이 없으면 헤더 없이 보내 서버가 AUTH401_2로 판단하게 둡니다.
      await dio.get(
        '/v8/members/me',
        options: Options(headers: {'Authorization': 'Bearer old'}),
      );
      expect(sent.last.containsKey('Authorization'), isFalse);

      storage.token = 'new';
      await dio.get('/v8/members/me');
      expect(sent.last['Authorization'], 'Bearer new');
    });

    test('저장소를 읽지 못하면 보내지 않고 서버 401과 다른 오류로 실패한다', () async {
      final sent = <Map<String, dynamic>>[];
      final dio = _dio(InMemoryTokenStorage('jwt')..failRead = true, sent);

      await expectLater(
        dio.get('/v8/members/me'),
        throwsA(
          isA<DioException>()
              .having((e) => e.response, 'response', isNull)
              .having((e) => e.error, 'error', isA<StateError>()),
        ),
      );
      expect(sent, isEmpty);
    });
  });

  group('redactTokens', () {
    test('로그인 응답 로그의 accessToken 값을 가린다', () {
      const log =
          '{isSuccess: true, code: COMMON200, result: {nickname: 밍고, accessToken: eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOjF9.abc_DEF-1}}';

      final redacted = redactTokens(log);

      expect(redacted, contains('accessToken: ***'));
      expect(redacted, contains('nickname: 밍고'));
      expect(redacted, isNot(contains('eyJ')));
    });

    test('JSON 형태와 키 없이 섞인 JWT도 가린다', () {
      expect(
        redactTokens('{"nickname":"밍고","accessToken":"abc.def.ghi"}'),
        '{"nickname":"밍고","accessToken":***}',
      );
      expect(redactTokens('token eyJa.eyJb.c end'), 'token *** end');
    });
  });
}
