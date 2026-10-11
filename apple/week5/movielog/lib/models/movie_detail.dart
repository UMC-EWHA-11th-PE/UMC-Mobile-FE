import 'movie.dart';

/// W3-03 영화 상세 화면에 표시할 정보입니다.
/// Figma에 상세 내용이 있는 영화는 Mock 상세 데이터에서, 나머지는 [Movie] 기본 정보로 만듭니다.
class MovieDetail {
  const MovieDetail({
    required this.title,
    required this.heroAsset,
    required this.year,
    required this.genres,
    required this.rating,
    this.runtimeMinutes,
    this.reviewCount,
    this.tags = const [],
    this.synopsis = const [],
  });

  /// 상세 내용이 없는 영화는 목록 정보만으로 상세 화면을 구성합니다.
  MovieDetail.fromMovie(Movie movie)
    : title = movie.title,
      heroAsset = movie.posterAsset,
      year = movie.year,
      genres = [movie.genre],
      rating = movie.rating,
      runtimeMinutes = null,
      reviewCount = null,
      tags = [movie.genre],
      synopsis = const [];

  final String title;

  /// 상단 히어로 이미지 (2:3으로 잘라 표시)
  final String heroAsset;
  final int year;
  final List<String> genres;
  final double rating;
  final int? runtimeMinutes;

  /// 별점 참여 수 — 예: (1,245)
  final int? reviewCount;

  /// 장르 칩 — 예: 로맨스, 드라마, 감동적인
  final List<String> tags;

  /// 시놉시스 문단
  final List<String> synopsis;
}
