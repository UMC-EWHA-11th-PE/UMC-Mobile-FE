import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:movielog/core/network/api_error.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/session/auth_session_bridge.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/core/utils/map_bounded.dart';
import 'package:movielog/data/models/favorite_check_dto.dart';
import 'package:movielog/data/models/favorite_response_dto.dart';

import 'fake_auth.dart';
import 'fake_favorites.dart';
import 'fake_tmdb.dart';

/// AuthInterceptor를 거친 뒤 'METHOD path' → Authorization 헤더 유무를 기록합니다.
Dio _recordingDio(Map<String, bool> sent) {
  return Dio(BaseOptions(baseUrl: 'https://workbook.devnoco.com'))
    ..interceptors.addAll([
      AuthInterceptor(InMemoryTokenStorage('jwt')),
      InterceptorsWrapper(
        onRequest: (options, handler) {
          sent['${options.method} ${options.uri.path}'] = options.headers
              .containsKey('Authorization');
          handler.resolve(Response(requestOptions: options, statusCode: 200));
        },
      ),
    ]);
}

void main() {
  group('AuthInterceptor v8 보호 경로', () {
    test('즐겨찾기 등록·목록·여부·해제에는 JWT를 붙인다', () async {
      final sent = <String, bool>{};
      final dio = _recordingDio(sent);

      await dio.post('/v8/favorites');
      await dio.get('/v8/favorites');
      await dio.get('/v8/favorites/550');
      await dio.delete('/v8/favorites/550');
      await dio.post('/v8/movie-records');
      await dio.get('/v8/members/me');
      await dio.post('/v8/ratings');

      expect(sent.values, everyElement(isTrue));
    });

    test('명세에 없는 메서드·경로·이전 버전에는 붙이지 않는다', () async {
      final sent = <String, bool>{};
      final dio = _recordingDio(sent);

      await dio.delete('/v8/favorites'); // 목록 경로의 DELETE는 없음
      await dio.post('/v8/favorites/550'); // 단건 경로의 POST는 없음
      await dio.get('/v8/favorites/0'); // movieId는 1 이상
      await dio.get('/v8/favorites/abc');
      await dio.get('/v7/favorites');
      await dio.get('/v7/members/me');
      await dio.post('/v8/auth/login');
      await dio.get('/v8/members/1/ratings');

      expect(sent.values, everyElement(isFalse));
    });
  });

  group('SessionGuard / AuthSessionBridge', () {
    test('세션을 시작할 때마다 generation이 올라가고, 현재 세션만 isCurrent', () {
      final guard = SessionGuard();
      final first = guard.startSession('a@example.com');
      expect(guard.isCurrent(first, 'a@example.com'), isTrue);

      // 같은 이메일로 다시 로그인해도 새 세션
      final second = guard.startSession('a@example.com');
      expect(guard.isCurrent(first, 'a@example.com'), isFalse);
      expect(guard.isCurrent(second, 'a@example.com'), isTrue);

      guard.invalidate();
      expect(guard.accountId, isNull);
      expect(guard.isCurrent(second, 'a@example.com'), isFalse);
    });

    test('sessionVersion이나 검증된 email이 바뀔 때만 새 세션을 시작한다', () {
      final signals = ChangeNotifier();
      var version = 1;
      String? email;
      final bridge = AuthSessionBridge(
        authSignals: signals,
        sessionVersion: () => version,
        verifiedEmail: () => email,
      );
      final guard = bridge.guard;
      expect(guard.accountId, isNull);

      // 내 정보가 늦게 로드되면 그때 계정을 연결
      email = 'a@example.com';
      signals.notifyListeners();
      final started = guard.generation;
      expect(guard.accountId, 'a@example.com');

      // 닉네임 수정 등 같은 값으로 알림만 오면 세션 유지
      signals.notifyListeners();
      expect(guard.generation, started);

      // 같은 이메일로 다시 로그인 → sessionVersion이 바뀌어 새 세션
      version = 2;
      signals.notifyListeners();
      expect(guard.generation, greaterThan(started));
      expect(guard.accountId, 'a@example.com');

      // 로그아웃 → 계정 없음
      version = 3;
      email = null;
      signals.notifyListeners();
      expect(guard.accountId, isNull);

      bridge.dispose();
      signals.dispose();
    });
  });

  group('mapBounded', () {
    test('결과는 입력 순서대로, 동시 실행은 최대 concurrency개', () async {
      var running = 0;
      var maxRunning = 0;
      final result = await mapBounded<int, String>(
        List.generate(12, (i) => i),
        5,
        (i) async {
          running++;
          maxRunning = running > maxRunning ? running : maxRunning;
          await Future<void>.delayed(Duration(milliseconds: 12 - i));
          running--;
          return '영화 $i';
        },
      );

      expect(result, List.generate(12, (i) => '영화 $i'));
      expect(maxRunning, 5);
    });

    test('빈 목록이면 바로 빈 결과', () async {
      expect(await mapBounded<int, int>(const [], 5, (i) async => i), isEmpty);
    });

    test('concurrency가 0 이하면 ArgumentError', () {
      expect(
        () => mapBounded<int, int>([1], 0, (i) async => i),
        throwsArgumentError,
      );
    });
  });

  group('FavoriteApiService', () {
    test('등록 → 목록 → 여부 → 해제 (해제는 200 + result null)', () async {
      final server = FakeFavoriteServer();
      final api = server.service;

      final created = await api.addFavorite(movieId: 550);
      expect(created.movieId, 550);
      expect(created.createdAt, DateTime.utc(2026, 9, 6, 12, 14, 3));

      expect((await api.fetchMyFavorites()).map((f) => f.movieId), [550]);
      final check = await api.checkFavorite(movieId: 550);
      expect(check.movieId, 550);
      expect(check.isFavorite, isTrue);

      await api.deleteFavorite(movieId: 550);
      expect((await api.checkFavorite(movieId: 550)).isFavorite, isFalse);
      expect(await api.fetchMyFavorites(), isEmpty);

      expect(server.calls, [
        'POST /v8/favorites',
        'GET /v8/favorites',
        'GET /v8/favorites/550',
        'DELETE /v8/favorites/550',
        'GET /v8/favorites/550',
        'GET /v8/favorites',
      ]);
    });

    test('이미 등록·이미 해제는 DioException + code 그대로 넘긴다', () async {
      final api = FakeFavoriteServer(movieIds: [550]).service;

      await expectLater(
        api.addFavorite(movieId: 550),
        throwsA(
          isA<DioException>().having(apiErrorCode, 'code', 'FAVORITE409_1'),
        ),
      );
      await expectLater(
        api.deleteFavorite(movieId: 999),
        throwsA(
          isA<DioException>().having(apiErrorCode, 'code', 'FAVORITE404_1'),
        ),
      );
    });
  });

  test('TmdbMovieService.fetchMovie — 상세 genres를 카드용 genre_ids로 바꾼다', () async {
    final requests = <Uri>[];
    final service = fakeTmdbService(requests: requests);
    final movie = await service.fetchMovie(fakeTmdbMovies.first['id'] as int);

    expect(movie.id, fakeTmdbMovies.first['id']);
    expect(
      movie.genreIds,
      containsAll(fakeTmdbMovies.first['genre_ids'] as List),
    );
    expect(requests.single.path, endsWith('/movie/${movie.id}'));
  });

  test('TmdbMovieService.searchMovies — query·page를 보낸다', () async {
    final requests = <Uri>[];
    final service = fakeTmdbService(requests: requests);
    final page = await service.searchMovies(query: '별빛', page: 2);

    expect(page.page, 2);
    expect(requests.single.path, endsWith('/search/movie'));
    expect(requests.single.queryParameters['query'], '별빛');
    expect(requests.single.queryParameters['page'], '2');
  });

  group('즐겨찾기 DTO', () {
    test('여부 응답에는 movieId가 없어 요청한 값을 함께 넘긴다', () {
      final dto = FavoriteCheckDto.fromJson({'isFavorite': true}, movieId: 550);
      expect(dto.movieId, 550);
      expect(dto.isFavorite, isTrue);
    });

    test('형식이 다르면 FormatException', () {
      expect(
        () => FavoriteCheckDto.fromJson({'isFavorite': 'yes'}, movieId: 1),
        throwsFormatException,
      );
      expect(() => FavoriteResponseDto.fromJson([]), throwsFormatException);
    });
  });
}
