/// 서버 평점은 1~5 사이 정수입니다. (7주차)
int validateServerScore(double value) {
  if (value < 1 || value > 5 || value != value.roundToDouble()) {
    throw ArgumentError('서버 평점은 1~5 사이 정수여야 합니다.');
  }
  return value.toInt();
}

/// v7 평점 등록 body. memberId는 넣지 않습니다(토큰으로 식별).
class CreateRatingRequest {
  const CreateRatingRequest({
    required this.movieId,
    required this.score,
    this.comment,
  });

  final int movieId; // 5주차 TmdbMovieDto.id
  final int score;
  final String? comment;

  Map<String, dynamic> toJson() => {
        'movieId': movieId,
        'score': score,
        if (comment != null && comment!.trim().isNotEmpty)
          'comment': comment!.trim(),
      };
}
