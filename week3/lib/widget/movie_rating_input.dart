import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onRatingUpdate,
  });

  final double rating;
  final ValueChanged<double> onRatingUpdate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingBar.builder(
          initialRating: rating,
          minRating: 1,
          allowHalfRating: true,
          itemCount: 5,
          itemSize: 40,
          itemBuilder: (context, index) {
            return const Icon(Icons.star);
          },
          onRatingUpdate: onRatingUpdate,
        ),

        const SizedBox(height: 12),

        Text(
          rating == 0
              ? '평점을 선택해주세요'
              : '$rating점',
        ),
      ],
    );
  }
}