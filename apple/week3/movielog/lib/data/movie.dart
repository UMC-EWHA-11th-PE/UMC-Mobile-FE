class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.rating,
    required this.posterAsset,
  });

  final int id;
  final String title;
  final String genre;
  final int year;

  /// 평균 별점 (5점 만점)
  final double rating;
  final String posterAsset;
}

/// W3-02 영화 목록 Figma 기준 Mock 데이터입니다.
/// posterAsset은 목록 카드(2:3)용 세로 포스터입니다.
const movies = [
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2023,
    rating: 4.8,
    posterAsset: 'assets/images/posters/card_us_under_the_starlight.png',
  ),
  Movie(
    id: 2,
    title: '우주의 끝에서',
    genre: 'SF',
    year: 2024,
    rating: 4.2,
    posterAsset: 'assets/images/posters/card_echoes_of_the_void.png',
  ),
  Movie(
    id: 3,
    title: '기억의 숲',
    genre: '애니메이션',
    year: 2022,
    rating: 4.9,
    posterAsset: 'assets/images/posters/card_whispering_woods.png',
  ),
  Movie(
    id: 4,
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2024,
    rating: 3.8,
    posterAsset: 'assets/images/posters/card_night_shadows.png',
  ),
  Movie(
    id: 5,
    title: '봄날의 커피',
    genre: '로맨스',
    year: 2021,
    rating: 4.5,
    posterAsset: 'assets/images/posters/card_fourth_afternoon.png',
  ),
  Movie(
    id: 6,
    title: '도시의 선',
    genre: '다큐멘터리',
    year: 2023,
    rating: 4.1,
    posterAsset: 'assets/images/posters/card_city_rhythm.png',
  ),
];

/// 필터 칩에 표시할 장르 목록 — 영화 목록에 처음 등장한 순서대로
List<String> get movieGenres => {for (final movie in movies) movie.genre}.toList();

Movie? findMovieById(int? id) {
  for (final movie in movies) {
    if (movie.id == id) return movie;
  }
  return null;
}
