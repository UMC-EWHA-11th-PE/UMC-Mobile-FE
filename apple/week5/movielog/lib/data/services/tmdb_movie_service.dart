import 'package:dio/dio.dart';

import '../models/tmdb_genre_dto.dart';
import '../models/tmdb_movie_dto.dart';
import '../models/tmdb_movie_page.dart';

/// TMDB API를 호출하고 응답 JSON을 DTO로 바꿉니다.
///
/// HTTP 요청과 DTO 변환만 담당합니다.
/// "인기 5개", "최대 30개", "선택된 장르" 같은 화면 정책은 ViewModel에서 다룹니다.
/// 상태를 저장하지 않으므로 여러 ViewModel이 인스턴스 하나를 함께 씁니다.
class TmdbMovieService {
  TmdbMovieService(this._dio);

  final Dio _dio;

  /// 인기 영화 — GET /movie/popular
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async {
    final response = await _dio.get(
      '/movie/popular',
      queryParameters: {'language': 'ko-KR', 'page': page},
    );
    return TmdbMoviePageDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// 영화 탐색 — GET /discover/movie
  /// [genreId]가 null이면 with_genres 없이 전체 장르를 조회합니다.
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    int? genreId,
  }) async {
    final response = await _dio.get(
      '/discover/movie',
      queryParameters: {
        'language': 'ko-KR',
        'page': page,
        'sort_by': 'popularity.desc',
        'include_adult': false,
        'include_video': false,
        if (genreId != null) 'with_genres': genreId,
      },
    );
    return TmdbMoviePageDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// 영화 장르 목록 — GET /genre/movie/list
  Future<List<TmdbGenreDto>> fetchGenres() async {
    final response = await _dio.get(
      '/genre/movie/list',
      queryParameters: {'language': 'ko'},
    );
    final data = response.data as Map<String, dynamic>;
    final genres = data['genres'] as List<dynamic>? ?? const [];
    return genres
        .map((item) => TmdbGenreDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
