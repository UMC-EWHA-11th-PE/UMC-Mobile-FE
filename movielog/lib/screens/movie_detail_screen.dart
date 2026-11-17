import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../view_models/session_ratings_view_model.dart';
import '../widgets/delete_rating_dialog.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

/// TMDB 영화 정보 + 이번 세션에서 남긴 내 평점(등록·수정·삭제)
class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movie});

  final TmdbMovieDto movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool isFavorite = false;

  TmdbMovieDto get movie => widget.movie;

  void toggleFavorite() {
    setState(() => isFavorite = !isFavorite);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  /// 평점 등록: POST /v7/ratings (movieId = TMDB id)
  Future<void> openCreateDialog() async {
    final ratings = context.read<SessionRatingsViewModel>();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것을 막습니다.
      builder: (_) => RatingDialog(
        onSubmit: (score, comment) => ratings.createRating(
          movieId: movie.id,
          score: score,
          comment: comment,
        ),
      ),
    );
    if (!mounted || saved != true) return;
    _showSnackBar('평점을 등록했습니다.');
  }

  /// 평점 수정: PATCH /v7/ratings/{ratingId}
  /// 기존 score·comment를 채워서 열고, 두 값을 항상 함께 보냅니다.
  Future<void> openEditDialog(RatingDto rating) async {
    final ratings = context.read<SessionRatingsViewModel>();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        initialScore: rating.score,
        initialComment: rating.comment, // null이면 빈 칸으로 시작
        onSubmit: (score, comment) => ratings.updateRating(
          rating: rating,
          score: score,
          comment: comment,
        ),
      ),
    );
    if (!mounted || saved != true) return;
    _showSnackBar('평점을 수정했습니다.');
  }

  /// 평점 삭제: DELETE /v7/ratings/{ratingId} (확인 Dialog 필수)
  Future<void> openDeleteDialog(RatingDto rating) async {
    final ratings = context.read<SessionRatingsViewModel>();
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          DeleteRatingDialog(onConfirm: () => ratings.deleteRating(rating)),
    );
    if (!mounted || deleted != true) return;
    _showSnackBar('평점을 삭제했습니다.');
  }

  @override
  Widget build(BuildContext context) {
    final myRating = context.select<SessionRatingsViewModel, RatingDto?>(
      (vm) => vm.ratingFor(movie.id),
    );
    final date = movie.releaseDate;
    final year = (date != null && date.length >= 4) ? date.substring(0, 4) : null;
    final score = movie.voteAverage / 2; // TMDB 10점 → 5점 별

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
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 0.67,
            child: TmdbPosterImage(
              posterPath: movie.posterPath,
              width: double.infinity,
              height: double.infinity,
            ),
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
                if (year != null) ...[
                  const SizedBox(height: 4),
                  Text(year, style: const TextStyle(color: AppColors.darkGray)),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    RatingBarIndicator(
                      rating: score,
                      itemCount: 5,
                      itemSize: 20,
                      itemBuilder: (context, index) =>
                          const Icon(Icons.star, color: AppColors.violet),
                    ),
                    const SizedBox(width: 8),
                    Text(movie.voteAverage.toStringAsFixed(1)),
                  ],
                ),
                if (myRating != null) ...[
                  const SizedBox(height: 24),
                  _MyRatingCard(
                    rating: myRating,
                    onEdit: () => openEditDialog(myRating),
                    onDelete: () => openDeleteDialog(myRating),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  '시놉시스',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                movie.overview.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text('줄거리 정보가 없어요.'),
                        ),
                      )
                    : Text(movie.overview, style: const TextStyle(height: 1.6)),
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
                  icon: Icon(
                    isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  ),
                  label: const Text('즐겨찾기'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: myRating == null
                      ? openCreateDialog
                      : () => openEditDialog(myRating),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.violet,
                    foregroundColor: AppColors.white,
                  ),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: Text(myRating == null ? '평점 남기기' : '평점 수정'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyRatingCard extends StatelessWidget {
  const _MyRatingCard({
    required this.rating,
    required this.onEdit,
    required this.onDelete,
  });

  final RatingDto rating;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final created = rating.createdAt.toLocal();
    final dateText =
        '${created.year}.${created.month.toString().padLeft(2, '0')}.${created.day.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.violet.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '내 평점',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              TextButton(onPressed: onEdit, child: const Text('수정')),
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(foregroundColor: AppColors.red),
                child: const Text('삭제'),
              ),
            ],
          ),
          RatingBarIndicator(
            rating: rating.score.toDouble(),
            itemCount: 5,
            itemSize: 20,
            itemBuilder: (context, index) =>
                const Icon(Icons.star, color: AppColors.violet),
          ),
          // comment가 null이면 표시하지 않습니다.
          if (rating.comment != null) ...[
            const SizedBox(height: 8),
            Text(rating.comment!),
          ],
          const SizedBox(height: 8),
          Text(dateText, style: const TextStyle(color: AppColors.gray)),
        ],
      ),
    );
  }
}
