import 'movie.dart';

/// W3-03 영화 상세 화면에 표시할 정보입니다.
/// Figma에 상세 내용이 있는 영화는 [_movieDetails]에서, 나머지는 [Movie] 기본 정보로 만듭니다.
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

/// Figma W3-03 기준 상세 내용 (영화 id → 상세)
const _movieDetails = {
  1: MovieDetail(
    title: '별빛 아래 우리',
    heroAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
    year: 2024,
    genres: ['로맨스', '드라마'],
    runtimeMinutes: 124,
    rating: 4.5,
    reviewCount: 1245,
    tags: ['로맨스', '드라마', '감동적인'],
    synopsis: [
      '바쁜 현대 사회 속에서 서로의 존재를 잊고 살아가던 두 남녀가 우연한 계기로 '
          '작은 천문대에서 만나게 됩니다. 매일 밤 별을 관측하며 서로의 상처를 치유하고, '
          '잊고 있던 꿈과 사랑을 다시금 깨닫게 되는 따뜻한 이야기입니다.',
      '과거의 아픔으로 인해 사람에게 마음을 열지 못하던 여주인공은, 별자리처럼 변함없는 '
          '모습으로 자신을 기다려주는 남주인공을 통해 서서히 마음의 문을 열게 됩니다. '
          '하지만 두 사람 앞에 놓인 현실적인 장벽들은 그들의 관계를 시험하게 되는데...',
      '별이 쏟아지는 밤하늘 아래, 그들이 나눈 조용한 약속들은 과연 영원할 수 있을까요? '
          '눈부신 영상미와 감성적인 OST가 어우러져 깊은 여운을 남기는 올 겨울 최고의 로맨스 영화.',
      '잔잔한 감동과 함께 삶의 의미를 다시 한번 되돌아보게 만드는 수작입니다.',
    ],
  ),
};

/// 영화 id로 상세 정보를 찾습니다. 없는 영화면 null입니다.
MovieDetail? findMovieDetailById(int? id) {
  final movie = findMovieById(id);
  if (movie == null) return null;
  return _movieDetails[movie.id] ?? MovieDetail.fromMovie(movie);
}
