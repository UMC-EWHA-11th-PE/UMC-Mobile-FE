/// 영화 한 편의 기록을 나타내는 모델.
class Movie {
  const Movie({
    required this.title,
    required this.director,
    required this.releaseYear,
    required this.rating,
  });

  /// 영화 제목
  final String title;

  /// 감독 이름
  final String director;

  /// 개봉 연도
  final int releaseYear;

  /// 내가 매긴 평점 (0.0 ~ 5.0)
  final double rating;

  @override
  String toString() => '$title ($releaseYear) - $director ⭐ $rating';
}
