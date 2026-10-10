import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'fake_movie_service.dart';
import 'movie.dart';

/// 유저별 평점 조회 API(GET /members/{memberId}/ratings)를 호출합니다.
///
/// 영화 목록 탭은 4주차까지 Mock 영화를 보여줬고,
/// 5주차부터는 내가 평점을 남긴 영화를 최신순으로 보여줍니다.
class RatingService {
  RatingService({http.Client? client}) : _client = client ?? ApiConfig.client;

  final http.Client _client;

  Future<List<Movie>> fetchRatedMovies({
    int memberId = ApiConfig.memberId,
  }) async {
    final http.Response response;
    try {
      response = await _client.get(
        ApiConfig.uri(['members', '$memberId', 'ratings']),
      );
    } catch (_) {
      throw const MovieLoadException('서버에 연결할 수 없습니다.');
    }

    if (response.statusCode == 404) {
      throw const MovieLoadException('존재하지 않는 유저입니다.');
    }
    if (response.statusCode != 200) {
      throw MovieLoadException('영화를 불러오지 못했습니다. (${response.statusCode})');
    }

    // 한글 한줄평이 깨지지 않도록 bytes를 UTF-8로 직접 디코딩합니다.
    final ratings =
        jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return [for (final json in ratings) _toMovie(json as Map<String, dynamic>)];
  }

  /// 서버는 movieId와 점수만 주므로 제목·포스터는 앱의 영화 데이터에서 찾고,
  /// 별점 칩에는 서버에 저장된 내 점수를 보여줍니다.
  Movie _toMovie(Map<String, dynamic> json) {
    final movieId = (json['movieId'] as num).toInt();
    final score = (json['score'] as num).toDouble();
    final movie = findMovieById(movieId);

    if (movie == null) {
      // 앱 데이터에 없는 영화 — 포스터 없이 ID로만 표시합니다.
      return Movie(
        id: movieId,
        title: '영화 #$movieId',
        genre: '정보 없음',
        year: DateTime.parse(json['createdAt'] as String).year,
        rating: score,
        posterAsset: '',
      );
    }

    return Movie(
      id: movie.id,
      title: movie.title,
      genre: movie.genre,
      year: movie.year,
      rating: score,
      posterAsset: movie.posterAsset,
    );
  }
}
