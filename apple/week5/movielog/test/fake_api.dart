import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:movielog/data/mock/movie_mock_data.dart';

/// 서버 없이 화면을 테스트하기 위한 가짜 movie 서버입니다.
/// - GET /members/{memberId}/ratings → Mock 영화 6개에 평점을 남긴 응답
/// - GET /members/nickname/{nickname}, /members/email/{email} → 모두 사용 가능
MockClient fakeApiClient() => MockClient((request) async {
  final segments = request.url.pathSegments;

  if (segments.length == 3 && segments.last == 'ratings') {
    final ratings = [
      for (final (index, movie) in movies.indexed)
        {
          'ratingId': movies.length - index,
          'movieId': movie.id,
          'score': movie.rating,
          'comment': null,
          'createdAt': '2026-10-10T17:00:00',
          'updatedAt': '2026-10-10T17:00:00',
        },
    ];
    return _json(ratings);
  }

  if (segments.length == 3 &&
      (segments[1] == 'nickname' || segments[1] == 'email')) {
    return _json({'available': true});
  }

  return http.Response('Not Found', 404);
});

http.Response _json(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json'},
);
