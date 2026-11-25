import 'favorite_response_dto.dart';
import 'tmdb_movie_dto.dart';

/// 내 즐겨찾기 목록 카드 하나 — MovieLog 즐겨찾기 + TMDB 영화 정보를 movieId로 결합한 결과
///
/// - [movie]가 있으면 제목·포스터를 보여줍니다.
/// - [movie]가 없고 [errorMessage]가 있으면 TMDB 조회 실패 — placeholder와 "정보 다시 불러오기"
/// - 둘 다 없으면 아직 TMDB 정보를 불러오는 중입니다.
class FavoriteListItem {
  const FavoriteListItem({
    required this.favorite,
    this.movie,
    this.errorMessage,
  });

  final FavoriteResponseDto favorite;
  final TmdbMovieDto? movie;
  final String? errorMessage;

  bool get hasMovie => movie != null;

  int get movieId => favorite.movieId;
}
