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
  // 에셋 팩의 poster_abyss_walker.jpg는 이름과 달리 MISSION: IMPROBABLE 이미지라
  // Figma에서 내보낸 ABYSS WALKER 포스터를 사용합니다.
  PopularMovie(
    title: '마션 레스큐',
    rating: 9.6,
    posterAsset: 'assets/images/posters/poster_martian_rescue.png',
  ),
  PopularMovie(
    title: '스파이 코드',
    rating: 9.2,
    posterAsset: 'assets/images/posters/poster_spy_code.png',
  ),
  // TODO: 포스터가 화면에 보이는 부분(76 x 200)만 잘린 이미지라 전체 이미지로 교체 필요
  PopularMovie(
    title: '비오는 날의 기억',
    rating: 8.9,
    posterAsset: 'assets/images/posters/poster_rainy_day.png',
  ),
];
