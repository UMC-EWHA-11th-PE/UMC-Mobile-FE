import 'favorite_response_dto.dart';
import 'tmdb_movie_dto.dart';

/// 내 즐겨찾기 목록 카드 하나에 필요한 데이터 — MovieLog 즐겨찾기 + TMDB 영화 정보
///
/// 두 서버의 응답을 movieId로 결합한 결과입니다.
/// - [movie]가 null이고 [movieFailed]가 false면 아직 TMDB 정보를 불러오는 중
/// - [movieFailed]가 true면 TMDB 조회 실패 — 카드에 placeholder와 "정보 다시 불러오기"를 보여줍니다.
class FavoriteListItem {
  const FavoriteListItem({
    required this.favorite,
    this.movie,
    this.movieFailed = false,
  });

  final FavoriteResponseDto favorite;
  final TmdbMovieDto? movie;
  final bool movieFailed;

  int get movieId => favorite.movieId;

  FavoriteListItem withMovie(TmdbMovieDto movie) =>
      FavoriteListItem(favorite: favorite, movie: movie);

  FavoriteListItem withMovieFailed() =>
      FavoriteListItem(favorite: favorite, movie: movie, movieFailed: true);

  FavoriteListItem withMovieLoading() =>
      FavoriteListItem(favorite: favorite, movie: movie);
}
