import 'package:flutter/material.dart';

import '../data/movie.dart';
import 'movie_card.dart';
import 'poster_badge.dart';

/// 영화 그리드 — 2열, column-gap 16, row-gap 24
class MovieGrid extends StatelessWidget {
  const MovieGrid({super.key, required this.movies});

  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 카드 너비 171 기준: 포스터 2:3(256.5) + 12 + 제목 24 + 소제목 24
        final itemWidth = (constraints.maxWidth - 16 * 2 - 16) / 2;
        return GridView.builder(
          // Figma padding-bottom 96 = 하단 네비(80) + 여백 16.
          // 네비가 본문을 덮지 않으므로 16만 둡니다.
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 24,
            mainAxisExtent: itemWidth * 1.5 + 12 + 24 + 24,
          ),
          itemCount: movies.length,
          itemBuilder: (context, index) => _MovieGridItem(movie: movies[index]),
        );
      },
    );
  }
}

/// 영화 아이템 — 공통 [MovieCard], 171 x 316.5
/// 포스터 171 x 256.5 (2:3, radius 12) + 12 + 제목 24 + 소제목 24
class _MovieGridItem extends StatelessWidget {
  const _MovieGridItem({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MovieCard(
      movie: movie,
      posterAspectRatio: 2 / 3,
      posterRadius: 12,
      // 별점 칩 — 48 x 24, 배경 #322F35CC, 글자 #F5EFF7
      badge: Positioned(
        top: 8,
        right: 8,
        child: PosterBadge(
          label: '★ ${movie.rating.toStringAsFixed(1)}',
          // #322F35 + 투명도 CC(204/255)
          backgroundColor: colors.inverseSurface.withValues(alpha: 0xCC / 0xFF),
          foregroundColor: colors.onInverseSurface,
        ),
      ),
      // 소제목 — 높이 24, opacity 0.8, Manrope 400 / 16 / 24, #494551
      subtitle: SizedBox(
        height: 24,
        child: Opacity(
          opacity: 0.8,
          child: Text(
            '${movie.year} · ${movie.genre}',
            style: textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
