/// 홈 화면 '인기 영화' 섹션에 표시할 Mock 데이터입니다.
/// 순위는 목록 순서(1부터)로 표시합니다.
class PopularMovie {
  const PopularMovie({
    required this.title,
    required this.rating,
    required this.posterAsset,
  });

  final String title;
  final double rating;
  final String posterAsset;
}

const popularMovies = [
  PopularMovie(
    title: '마션 레스큐',
    rating: 9.6,
    posterAsset: 'assets/images/posters/poster_abyss_walker.jpg',
  ),
  // TODO: 포스터 이미지 추가 필요 (Figma: MISSION: IMPROBABLE)
  PopularMovie(
    title: '스파이 코드',
    rating: 9.2,
    posterAsset: 'assets/images/posters/poster_spy_code.jpg',
  ),
  // TODO: 포스터 이미지 추가 및 전체 제목 확인 필요 (Figma에서 '비오는 날의'까지만 보임)
  PopularMovie(
    title: '비오는 날의 그림자',
    rating: 8.9,
    posterAsset: 'assets/images/posters/poster_rainy_day.jpg',
  ),
];
