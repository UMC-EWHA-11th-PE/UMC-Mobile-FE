
import '../model/movie.dart';

enum MovieLoadMode {
  success,
  empty,
  failure,
}

class MovieLoadException implements Exception {
  const MovieLoadException(this.message);

  final String message;
}

class FakeMovieService {
  const FakeMovieService();

  Future<List<Movie>> fetchMovies({
    MovieLoadMode mode = MovieLoadMode.success,
  }) async {
    // 실제 API 요청 대신 1초 대기
    await Future<void>.delayed(
      const Duration(seconds: 1),
    );

    // TODO(5주차 유저별 평점 조회 API):
    // 실제 API Service로 교체할 때 연동 위치 확인

    return switch (mode) {
      MovieLoadMode.success => movies,
      MovieLoadMode.empty => <Movie>[],
      MovieLoadMode.failure =>
        throw const MovieLoadException(
          '영화를 불러오지 못했습니다.',
        ),
    };
  }
}
