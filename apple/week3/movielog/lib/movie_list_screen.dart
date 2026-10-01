import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/movie.dart';
import 'widgets/main_header.dart';

/// W3-02 영화 목록 화면입니다.
///
/// 화면은 의미 단위로 나뉩니다.
/// - [MainHeader] 영화 제목, 검색 버튼
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
      appBar: const MainHeader(title: '영화'),
      body: CustomScrollView(
        slivers: [
          // 필터 칩 영역 — 358 x 40, 헤더 아래 8
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverToBoxAdapter(
              child: _GenreFilterBar(
                genres: [_allGenres, ...movieGenres],
                selected: _selectedGenre,
                onSelected: (genre) => setState(() => _selectedGenre = genre),
              ),
            ),
          ),
          // 영화 그리드 — 2열, column-gap 16, row-gap 24
          // Figma padding-bottom 96 = 하단 네비(80) + 여백 16. 네비가 본문을 덮지 않으므로 16만 둡니다.
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                // 카드 너비 171 기준: 포스터 2:3(256.5) + gap 4 + 제목 영역 56
                final itemWidth = (constraints.crossAxisExtent - 16) / 2;
                return SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 24,
                    mainAxisExtent: itemWidth * 1.5 + 4 + 56,
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
          shadows: [
            BoxShadow(
              offset: Offset(0, 1),
              blurRadius: 2,
              color: Color(0x0D000000),
            ),
          ],
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

/// 영화 아이템 — 171 x 316.5, gap 4
/// 포스터(171 x 256.5) + 제목 영역(padding-top 8, 제목 24, 소제목 24)
class _MovieGridItem extends StatelessWidget {
  const _MovieGridItem({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 카드를 누르면 영화 상세로 이동 (뒤로가기로 목록 복귀)
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/movies/${movie.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 배경+그림자 — radius 12, #E6E0E9, box-shadow 0 1 2 #0000000D
          AspectRatio(
            aspectRatio: 2 / 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Color(0x0D000000),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      movie.posterAsset,
                      fit: BoxFit.cover,
                      // 포스터가 없으면 배경색(#E6E0E9)만 보여줍니다.
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _RatingChip(rating: movie.rating),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 밑에 제목 — padding-top 8, 제목·소제목 각 24
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Manrope 500 / 16 / 24, #1D1B20
                SizedBox(
                  height: 24,
                  child: Text(
                    movie.title,
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 소제목 — opacity 0.8, Manrope 400 / 16 / 24, #494551
                SizedBox(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 포스터 위 별점 칩 — 48 x 24, radius 6, padding 4 / 8
/// 배경 #322F35CC, backdrop blur 4, 글자 Manrope 700 / 12 / 16 #F5EFF7
class _RatingChip extends StatelessWidget {
  const _RatingChip({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(6);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            // #322F35 + 투명도 CC(204/255)
            color: colors.inverseSurface.withValues(alpha: 0xCC / 0xFF),
            borderRadius: radius,
          ),
          child: Text(
            '★ ${rating.toStringAsFixed(1)}',
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onInverseSurface,
            ),
          ),
        ),
      ),
    );
  }
}
