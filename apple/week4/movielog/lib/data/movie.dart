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

/// 홈 '인기 영화' 섹션 Mock 데이터 (W3-01 Figma) — 순위는 목록 순서(1부터)
/// Figma 홈 카드는 10점 만점(9.6)으로 표시하므로 평점은 5점 만점 값으로 저장하고 화면에서 x2 합니다.
/// 장르·연도는 Figma에 없어 임의의 Mock 값입니다.
const popularMovies = [
  // 에셋 팩의 poster_abyss_walker.jpg는 이름과 달리 MISSION: IMPROBABLE 이미지라
  // Figma에서 내보낸 ABYSS WALKER 포스터를 사용합니다.
  Movie(
    id: 7,
    title: '마션 레스큐',
    genre: 'SF',
    year: 2024,
    rating: 4.8,
    posterAsset: 'assets/images/posters/poster_martian_rescue.png',
  ),
  Movie(
    id: 8,
    title: '스파이 코드',
    genre: '액션',
    year: 2024,
    rating: 4.6,
    posterAsset: 'assets/images/posters/poster_spy_code.png',
  ),
  // TODO: 포스터가 화면에 보이는 부분(76 x 200)만 잘린 이미지라 전체 이미지로 교체 필요
  Movie(
    id: 9,
    title: '비오는 날의 기억',
    genre: '드라마',
    year: 2023,
    rating: 4.45,
    posterAsset: 'assets/images/posters/poster_rainy_day.jpg',
  ),
];

/// 영화 목록·홈 인기 영화 어디에서 눌러도 같은 ID로 찾을 수 있습니다.
Movie? findMovieById(int? id) {
  for (final movie in [...movies, ...popularMovies]) {
    if (movie.id == id) return movie;
  }
  return null;
}
