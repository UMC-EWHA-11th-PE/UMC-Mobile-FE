import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../theme/app_colors.dart';
import '../widgets/movie_poster.dart';
import '../widgets/rating_dialog.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final String movieId;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool isFavorite = false;

  void toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> openRatingDialog() async {
    final rating = await showDialog<double>(
      context: context,
      builder: (context) => const RatingDialog(),
    );

    if (rating == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('평점 $rating점을 남겼습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final movie = findMovieById(int.tryParse(widget.movieId));

    if (movie == null) {
      return const Scaffold(
        body: Center(child: Text('영화를 찾을 수 없습니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Cinema Archive',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.violet),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 0.67,
            child: MoviePoster(asset: movie.posterAsset),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${movie.year} • ${movie.genre}',
                  style: const TextStyle(color: AppColors.darkGray),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    RatingBarIndicator(
                      rating: movie.rating,
                      itemCount: 5,
                      itemSize: 20,
                      itemBuilder: (context, index) {
                        return const Icon(Icons.star, color: AppColors.violet);
                      },
                    ),
                    const SizedBox(width: 8),
                    Text('${movie.rating}'),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  '시놉시스',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(movie.description, style: const TextStyle(height: 1.6)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: toggleFavorite,
                  icon: Icon(isFavorite ? Icons.bookmark : Icons.bookmark_border),
                  label: const Text('즐겨찾기'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: openRatingDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.violet,
                    foregroundColor: AppColors.white,
                  ),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Text('평점 남기기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
