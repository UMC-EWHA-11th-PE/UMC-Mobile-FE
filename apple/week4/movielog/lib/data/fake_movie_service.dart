import 'movie.dart';

/// Mock 응답 시나리오 — 화면에서 성공·빈 목록·실패 상태를 각각 확인하기 위해 사용합니다.
enum MovieLoadMode { success, empty, failure }

class MovieLoadException implements Exception {
  const MovieLoadException(this.message);

  final String message;
}

/// 3주차 Mock Data를 1초 뒤에 돌려주는 가짜 서비스입니다.
/// 화면은 내부 구현을 모르도록 두어, 5주차에 실제 API 호출로 교체합니다.
class FakeMovieService {
  const FakeMovieService();

  Future<List<Movie>> fetchMovies({
    MovieLoadMode mode = MovieLoadMode.success,
  }) async {
    // TODO(5주차 유저별 평점 조회 API): 지연 + Mock Data 반환을 실제 API 호출로 교체
    await Future<void>.delayed(const Duration(seconds: 1));

    return switch (mode) {
      MovieLoadMode.success => movies,
      MovieLoadMode.empty => const <Movie>[],
      MovieLoadMode.failure => throw const MovieLoadException(
        '영화를 불러오지 못했습니다.',
      ),
    };
  }
}
