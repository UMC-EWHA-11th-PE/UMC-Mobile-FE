import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../model/movie.dart';
import '../widget/movie_rating_input.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({
    super.key,
    required this.movieId,
  });

  final String movieId;

  @override
  State<MovieDetailScreen> createState() =>
      _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  double selectedRating = 0;
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(widget.movieId);
    final movie = findMovieById(id);

    if (movie == null) {
      return const Scaffold(
        body: Center(
          child: Text('영화를 찾을 수 없습니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cinema Archive'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 영화 포스터
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                movie.posterAsset,
                width: double.infinity,
                height: 420,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 24),

            // 영화 제목
            Text(
              movie.title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // 연도 · 장르
            Text(
              '${movie.year} · ${movie.genre}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 20),

            // 평균 평점
            Row(
              children: [
                RatingBarIndicator(
                  rating: 4.5,
                  itemCount: 5,
                  itemSize: 24,
                  itemBuilder: (context, index) {
                    return const Icon(
                      Icons.star,
                      color: Colors.amber,
                    );
                  },
                ),

                const SizedBox(width: 8),

                const Text(
                  '4.5',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // 즐겨찾기 버튼
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    isFavorite = !isFavorite;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFavorite
                            ? '즐겨찾기에 추가되었습니다.'
                            : '즐겨찾기에서 삭제되었습니다.',
                      ),
                    ),
                  );
                },
                icon: Icon(
                  isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
                label: Text(
                  isFavorite
                      ? '즐겨찾기 삭제'
                      : '즐겨찾기 추가',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 평점 남기기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showRatingDialog,
                child: const Text('평점 남기기'),
              ),
            ),

            // 저장한 내 평점 표시
            if (selectedRating > 0) ...[
              const SizedBox(height: 16),
              Text(
                '내 평점: $selectedRating',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRatingDialog() {
    double tempRating = selectedRating;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('평점 남기기'),

              content: MovieRatingInput(
                rating: tempRating,
                onRatingUpdate: (rating) {
                  setDialogState(() {
                    tempRating = rating;
                  });
                },
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('취소'),
                ),

                ElevatedButton(
                  onPressed: tempRating == 0
                      ? null
                      : () {
                          setState(() {
                            selectedRating = tempRating;
                          });

                          Navigator.pop(dialogContext);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '평점 $selectedRating점이 저장되었습니다.',
                              ),
                            ),
                          );
                        },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}