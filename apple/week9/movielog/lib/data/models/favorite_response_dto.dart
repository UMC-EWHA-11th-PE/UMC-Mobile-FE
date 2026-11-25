/// 즐겨찾기 하나 — 등록(POST) 응답의 result이자 내 목록(GET) 배열의 항목입니다.
///
/// 예) { "favoriteId": 3, "movieId": 550, "createdAt": "2026-09-06T12:14:03.000Z" }
///
/// 제목·포스터는 없습니다. [movieId](TMDB id)로 TMDB 영화 정보를 따로 가져와 합칩니다.
class FavoriteResponseDto {
  const FavoriteResponseDto({
    required this.favoriteId,
    required this.movieId,
    required this.createdAt,
  });

  /// MovieLog 서버의 즐겨찾기 id — 해제·여부 조회 경로에는 쓰지 않습니다. (movieId를 씀)
  final int favoriteId;

  /// TMDB 영화 id
  final int movieId;
  final DateTime createdAt;

  factory FavoriteResponseDto.fromJson(Map<String, dynamic> json) {
    return FavoriteResponseDto(
      favoriteId: (json['favoriteId'] as num).toInt(),
      movieId: (json['movieId'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
