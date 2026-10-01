import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:go_router/go_router.dart';

import 'data/movie.dart';
import 'data/popular_movie.dart';
import 'theme/app_colors.dart';

/// W3-01 영화 홈 화면입니다.
///
/// 화면은 의미 단위로 나뉩니다.
/// - [_HomeHeader] MovieLog 로고, 검색 버튼
/// - [_GreetingSection] 오늘은 어떤 영화를 볼까요?
/// - [_FeaturedBanner] 추천 신작 배너
/// - [_PopularSection] 인기 영화 가로 목록
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// 배너 보조 문구 — Mock 데이터에 러닝타임·복수 장르가 없어 Figma 문구를 그대로 사용합니다.
  static const _featuredMeta = '로맨스 · 드라마 · 120분';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _HomeHeader(),
      body: ListView(
        // Figma padding-bottom 96 = 하단 네비(80)에 가려지는 영역 + 여백 16.
        // 여기서는 네비가 본문을 덮지 않으므로 여백 16만 둡니다.
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const _GreetingSection(),
          // 중간 섹션 — padding 0 / 16 / 24 / 16
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: _FeaturedBanner(movie: movies.first, meta: _featuredMeta),
          ),
          const _PopularSection(movies: popularMovies),
        ],
      ),
    );
  }
}

/// 이미지 위 텍스트 그림자 — 0 4 3 #00000012, 0 2 2 #0000000F
const _textShadows = [
  Shadow(offset: Offset(0, 4), blurRadius: 3, color: Color(0x12000000)),
  Shadow(offset: Offset(0, 2), blurRadius: 2, color: Color(0x0F000000)),
];

/// greeting section — 388 x 104, padding 16
class _GreetingSection extends StatelessWidget {
  const _GreetingSection();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      // Manrope 500 / 28 / 36 / -0.7, #1D1B20
      child: Text(
        '오늘은 어떤\n영화를 볼까요?',
        style: textTheme.titleMedium?.copyWith(
          fontSize: 28,
          height: 36 / 28,
          letterSpacing: -0.7,
          color: colors.onSurface,
        ),
      ),
    );
  }
}

/// 중간 배너 — 356 x 534, radius 24, 배경 #E6E0E9
/// 포스터 → 오버레이(#000000B2) → 하단 정보(칩, 제목, 설명, 버튼) 순으로 쌓습니다.
class _FeaturedBanner extends StatelessWidget {
  const _FeaturedBanner({required this.movie, required this.meta});

  final Movie movie;

  /// 장르·러닝타임 문구 (예: 로맨스 · 드라마 · 120분)
  final String meta;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 534,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ColoredBox(
          // 이미지가 뜨기 전 보이는 배경
          color: colors.surfaceContainerHighest,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 뒤에 포스터 — 가로형 이미지를 가운데 기준으로 잘라 채웁니다.
              Image.asset(movie.posterAsset, fit: BoxFit.cover),
              const ColoredBox(color: AppColors.imageOverlay),
              // 배너 하단 — 356 x 218, padding 24
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 칩 마진 — padding-bottom 8
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _BannerChip(label: '추천 신작'),
                        ),
                      ),
                      // 제목 — padding-bottom 4, Manrope 500 / 28 / 36, #FFFFFF
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          movie.title,
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: 28,
                            height: 36 / 28,
                            color: AppColors.onImage,
                            shadows: _textShadows,
                          ),
                        ),
                      ),
                      // 하단 설명 — padding-bottom 16, opacity 0.9
                      // Manrope 400 / 16 / 24, #F8F2FA
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Opacity(
                          opacity: 0.9,
                          child: Text(
                            meta,
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.onImageVariant,
                              shadows: _textShadows,
                            ),
                          ),
                        ),
                      ),
                      _DetailButton(onPressed: () {}), // 상세 화면은 아직 연결하지 않습니다.
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 추천 신작 칩 — 75 x 34, radius 9999, padding 9.5 / 12 / 6.5 / 12
/// 배경 #4F378AE5, border 1px #FFFFFF33, box-shadow 0 1 2 #0000000D, backdrop blur 12
class _BannerChip extends StatelessWidget {
  const _BannerChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        shadows: [
          BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x0D000000)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 9.5, 12, 6.5),
            decoration: ShapeDecoration(
              // #4F378A + 투명도 E5(229/255)
              color: colors.onPrimaryContainer.withValues(alpha: 0xE5 / 0xFF),
              shape: const StadiumBorder(
                side: BorderSide(color: AppColors.onImageOutline),
              ),
            ),
            // 글자 스펙이 없어 칩 크기(높이 34 = 9.5 + 16 + 6.5 + 테두리 2)에서 역산: 12 / 16
            child: Text(
              label,
              style: textTheme.titleMedium?.copyWith(
                fontSize: 12,
                height: 16 / 12,
                color: AppColors.onImage,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 상세보기 버튼 — 308 x 48, radius 9999, padding 12 / 0, gap 8, 배경 #4F378A
/// box-shadow 0 2 4 -2 #0000001A, 0 4 6 -1 #0000001A
class _DetailButton extends StatelessWidget {
  const _DetailButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        shadows: [
          BoxShadow(
            offset: Offset(0, 2),
            blurRadius: 4,
            spreadRadius: -2,
            color: Color(0x1A000000),
          ),
          BoxShadow(
            offset: Offset(0, 4),
            blurRadius: 6,
            spreadRadius: -1,
            color: Color(0x1A000000),
          ),
        ],
      ),
      child: Material(
        color: colors.onPrimaryContainer,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 아이콘 16.67 x 16.67, #FFFFFF
                SvgPicture.asset(
                  'assets/icons/banner_info_filled.svg',
                  width: 50 / 3,
                  height: 50 / 3,
                  colorFilter: const ColorFilter.mode(
                    AppColors.onImage,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                // Manrope 500 / 16 / 24, #FFFFFF
                Text(
                  '상세보기',
                  style: textTheme.titleMedium?.copyWith(color: AppColors.onImage),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 헤더 — 388 x 64, padding 0 / 16, 배경 #FAF9F5, space-between
/// 왼쪽 MovieLog 로고, 오른쪽 검색 버튼
class _HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  const _HomeHeader();

  static const double _height = 64;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: colors.surface,
      // 상태 표시줄 영역까지 배경을 칠하고 내용은 그 아래에 배치
      child: SafeArea(
        bottom: false,
        child: Container(
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 헤딩 — Manrope 700 / 22 / 28 / -0.55, #4F378A
              Text(
                'MovieLog',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.55,
                  color: colors.onPrimaryContainer,
                ),
              ),
              // 우측 버튼 — 34 x 34, radius 9999, padding 8, 아이콘 18 x 18
              IconButton(
                onPressed: () {}, // 검색 화면은 아직 연결하지 않습니다.
                icon: SvgPicture.asset(
                  'assets/icons/header_search.svg',
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    colors.onPrimaryContainer,
                    BlendMode.srcIn,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                style: IconButton.styleFrom(
                  shape: const CircleBorder(),
                  // 기본 48x48 터치 영역 여백을 없애 Figma 34x34에 맞춤
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                tooltip: '검색',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 인기 영화 섹션 — 388 x 324, padding-bottom 8, gap 16
/// 제목 줄(28) + 가로 목록(272)
class _PopularSection extends StatelessWidget {
  const _PopularSection({required this.movies});

  final List<PopularMovie> movies;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 내부 컨테이너 — 388 x 28, padding 0 / 16, space-between
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Manrope 500 / 22 / 28, #1D1B20
                  Text('인기 영화', style: textTheme.titleLarge),
                  _SeeAllButton(onPressed: () => context.go('/movies')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 중앙 컨테이너 — 388 x 272, 카드 140 x 256, 간격 16
          SizedBox(
            height: 272,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: movies.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) => Align(
                alignment: Alignment.topCenter,
                child: _PopularMovieCard(rank: index + 1, movie: movies[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 전체보기 텍스트 버튼 — 67.93 x 24, gap 4, #4F378A
class _SeeAllButton extends StatelessWidget {
  const _SeeAllButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Manrope 500 / 16 / 24
          Text(
            '전체보기',
            style: textTheme.titleMedium?.copyWith(color: colors.onPrimaryContainer),
          ),
          const SizedBox(width: 4),
          // 아이콘 4.93 x 8
          SvgPicture.asset(
            'assets/icons/chevron_right.svg',
            width: 4.933,
            height: 8,
            colorFilter: ColorFilter.mode(colors.onPrimaryContainer, BlendMode.srcIn),
          ),
        ],
      ),
    );
  }
}

/// 영화 카드 — 140 x 256
/// 포스터(200) + 마진 12 + 제목(24) + 별점 영역(20)
class _PopularMovieCard extends StatelessWidget {
  const _PopularMovieCard({required this.rank, required this.movie});

  final int rank;
  final PopularMovie movie;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 140,
      child: Column(
        // 목록 높이(272)를 채우지 않고 카드 높이(256)만 차지
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 마진 — padding-bottom 12
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            // 배경 그림자 — 140 x 200, radius 16, #E6E0E9, box-shadow 0 1 2 #0000000D
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Color(0x0D000000),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 200,
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
                      Positioned(left: 8, top: 8, child: _RankChip(rank: rank)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 제목 — 140 x 24, Manrope 500 / 16 / 24, #1D1B20
          SizedBox(
            height: 24,
            child: Text(
              movie.title,
              style: textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 별점 영역 — padding-top 4, 내부 16, gap 4
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SizedBox(
              height: 16,
              child: Row(
                children: [
                  // 별 11.67 x 11.08, #C9A74D
                  SvgPicture.asset(
                    'assets/icons/rating_star_filled.svg',
                    width: 11.667,
                    height: 11.083,
                    colorFilter: ColorFilter.mode(colors.tertiary, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 4),
                  // Manrope 400 / 12 / 16, #494551
                  Text(
                    movie.rating.toStringAsFixed(1),
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 포스터 위 순위 칩 — 24 x 26, radius 6, padding 4 / 8
/// 배경 #00000099, border 1px #FFFFFF1A, backdrop blur 4
class _RankChip extends StatelessWidget {
  const _RankChip({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(6);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.rankChip,
            borderRadius: radius,
            border: Border.all(color: AppColors.rankChipOutline),
          ),
          // Manrope 700 / 12 / 16
          child: Text(
            '$rank',
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onImage,
            ),
          ),
        ),
      ),
    );
  }
}
