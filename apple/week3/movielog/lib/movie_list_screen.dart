import 'package:flutter/material.dart';

import 'data/movie.dart';
import 'theme/app_shadows.dart';
import 'widgets/app_header.dart';
import 'widgets/movie_card.dart';
import 'widgets/poster_badge.dart';

/// W3-02 영화 목록 화면입니다.
///
/// 화면은 의미 단위로 나뉩니다.
/// - [AppHeader] 영화 제목, 검색 버튼
/// - [_GenreFilterBar] 장르 필터 칩 (전체 + 장르)
/// - [_MovieGridItem] 2열 그리드의 영화 카드
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const _allGenres = '전체';

  /// 선택된 필터 — 처음에는 전체
  String _selectedGenre = _allGenres;

  List<Movie> get _filteredMovies => _selectedGenre == _allGenres
      ? movies
      : movies.where((movie) => movie.genre == _selectedGenre).toList();

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMovies;

    return Scaffold(
      appBar: const AppHeader.tab(title: '영화'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 필터 칩 영역 — 358 x 40, 헤더 아래 8, 그리드와 간격 16
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _GenreFilterBar(
              genres: [_allGenres, ...movieGenres],
              selected: _selectedGenre,
              onSelected: (genre) => setState(() => _selectedGenre = genre),
            ),
          ),
          // 영화 그리드 — 2열, column-gap 16, row-gap 24
          Expanded(
            child: LayoutBuilder(
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
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _MovieGridItem(movie: filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 필터 칩 영역 — 358 x 40, 가로 스크롤
/// 칩 높이는 32이고 아래 8은 그림자가 잘리지 않도록 남겨 둡니다.
class _GenreFilterBar extends StatelessWidget {
  const _GenreFilterBar({
    required this.genres,
    required this.selected,
    required this.onSelected,
  });

  final List<String> genres;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: genres.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _GenreChip(
          label: genres[index],
          selected: genres[index] == selected,
          onTap: () => onSelected(genres[index]),
        ),
      ),
    );
  }
}

/// 필터 칩 하나 — 높이 32, radius 9999, padding 8 / 16, box-shadow 0 1 2 #0000000D
/// 선택: 배경 #6750A4, 글자 #FFFFFF / 미선택: 배경 #E6E0E9, 글자 #494551
class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      selected: selected,
      button: true,
      child: DecoratedBox(
        decoration: const ShapeDecoration(
          shape: StadiumBorder(),
          shadows: AppShadows.card,
        ),
        child: Material(
          color: selected ? colors.primary : colors.surfaceContainerHighest,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              // Manrope 500 / 12 / 16, center
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: selected ? colors.onPrimary : colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
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
