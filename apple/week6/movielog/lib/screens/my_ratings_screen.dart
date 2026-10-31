import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_with_movie.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_list_states.dart';
import '../widgets/movie_rating_indicator.dart';
import '../widgets/tmdb_poster_image.dart';

/// 마이페이지 → 내가 등록한 평점 화면입니다.
///
/// [MyRatingsViewModel]의 상태를 [Consumer]로 구독해 그대로 그립니다.
/// - 불러오는 중: [MovieListLoading]
/// - 실패: [MovieListError] (상태 코드별 안내 + 다시 시도)
/// - 빈 목록: [_MyRatingsEmpty]
/// - 성공: 평점 목록 — TMDB 영화를 못 찾은 평점도 placeholder로 남깁니다.
///
/// 로그인이 없어 학습용 memberId의 샘플 평점을 읽기만 합니다.
/// 현재 사용자의 평점이라고 안내하거나 수정·삭제 버튼을 두지 않습니다.
/// 하단 NavigationBar 없이 root Navigator 위에 열립니다.
class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '내가 등록한 평점'),
      body: Consumer<MyRatingsViewModel>(
        builder: (context, viewModel, child) {
          return switch (viewModel.status) {
            MyRatingsLoadStatus.idle ||
            MyRatingsLoadStatus.loading => const MovieListLoading(),
            MyRatingsLoadStatus.error => MovieListError(
              message: viewModel.message,
              onRetry: viewModel.load,
            ),
            MyRatingsLoadStatus.empty => _MyRatingsEmpty(
              memberId: viewModel.memberId,
            ),
            MyRatingsLoadStatus.success => _MyRatingsList(
              memberId: viewModel.memberId,
              ratings: viewModel.ratings,
              message: viewModel.message,
            ),
          };
        },
      ),
    );
  }
}

/// 학습용 조회임을 알리는 문구 — 로그인 사용자의 평점으로 오해하지 않게 합니다.
class _SampleNotice extends StatelessWidget {
  const _SampleNotice({required this.memberId});

  final int memberId;

  @override
  Widget build(BuildContext context) {
    return Text(
      '학습용 memberId $memberId의 샘플 평점입니다.',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _MyRatingsEmpty extends StatelessWidget {
  const _MyRatingsEmpty({required this.memberId});

  final int memberId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('아직 등록된 평점이 없습니다.'),
          const SizedBox(height: 8),
          _SampleNotice(memberId: memberId),
        ],
      ),
    );
  }
}

/// 평점 목록 — 위에 샘플 안내와 (있으면) 영화 정보 누락 안내, gap 16
class _MyRatingsList extends StatelessWidget {
  const _MyRatingsList({
    required this.memberId,
    required this.ratings,
    required this.message,
  });

  final int memberId;
  final List<RatingWithMovie> ratings;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final notice = message;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        _SampleNotice(memberId: memberId),
        if (notice != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: colors.error),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  notice,
                  style: textTheme.bodySmall?.copyWith(color: colors.error),
                ),
              ),
            ],
          ),
        ],
        for (final entry in ratings) ...[
          const SizedBox(height: 16),
          _RatingTile(entry: entry),
        ],
      ],
    );
  }
}

/// 평점 하나 — 포스터 60x90 + 제목·별점·한줄평·등록일
class _RatingTile extends StatelessWidget {
  const _RatingTile({required this.entry});

  final RatingWithMovie entry;

  /// 예) 2026.09.06
  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${local.year}.${twoDigits(local.month)}.${twoDigits(local.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rating = entry.rating;
    final movie = entry.movie;
    final comment = rating.comment;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          // movie가 null이면 posterPath도 null이라 placeholder가 그려집니다.
          child: TmdbPosterImage(
            posterPath: movie?.posterPath,
            width: 60,
            height: 90,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movie?.title ?? '영화 정보를 찾을 수 없어요',
                style: textTheme.titleMedium,
              ),
              // 영화 정보가 없으면 어떤 영화의 평점인지 movieId로 알려줍니다.
              if (movie == null)
                Text('movieId ${rating.movieId}', style: textTheme.bodySmall),
              const SizedBox(height: 4),
              MovieRatingIndicator(
                rating: rating.score.toDouble(),
                itemSize: 16,
              ),
              if (comment != null) ...[
                const SizedBox(height: 4),
                Text(comment, style: textTheme.bodyMedium),
              ],
              const SizedBox(height: 4),
              Text(_formatDate(rating.createdAt), style: textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
