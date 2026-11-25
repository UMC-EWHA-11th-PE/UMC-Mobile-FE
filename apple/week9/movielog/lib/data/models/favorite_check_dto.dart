/// 특정 영화 즐겨찾기 여부(GET /v8/favorites/{movieId}) 응답의 result입니다.
///
/// 예) { "isFavorite": true }
class FavoriteCheckDto {
  const FavoriteCheckDto({required this.isFavorite});

  final bool isFavorite;

  factory FavoriteCheckDto.fromJson(Map<String, dynamic> json) {
    return FavoriteCheckDto(isFavorite: json['isFavorite'] as bool);
  }
}
