import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

/// 수정할 필요가 없는 별점(내 별점, 평균 별점 등)을 읽기 전용으로 표시
class MovieRatingIndicator extends StatelessWidget {
  const MovieRatingIndicator({
    super.key,
    required this.rating,
    this.itemSize = 20,
    this.showValue = true,
  });

  final double rating;
  final double itemSize;

  /// 별 옆에 숫자(예: 4.3)를 함께 표시할지 여부
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingBarIndicator(
          rating: rating,
          itemCount: 5,
          itemSize: itemSize,
          itemBuilder: (context, index) {
            return const Icon(
              Icons.star,
              color: Colors.amber,
            );
          },
        ),
        if (showValue) ...[
          const SizedBox(width: 8),
          Text(rating.toStringAsFixed(1)),
        ],
      ],
    );
  }
}
