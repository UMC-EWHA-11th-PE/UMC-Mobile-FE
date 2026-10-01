import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:go_router/go_router.dart';

import 'data/movie.dart';
import 'data/popular_movie.dart';
import 'theme/app_colors.dart';
import 'theme/app_shadows.dart';
import 'widgets/app_header.dart';
import 'widgets/pill_button.dart';
import 'widgets/poster_badge.dart';
import 'widgets/poster_image.dart';

/// W3-01 영화 홈 화면입니다.
///
/// 화면은 의미 단위로 나뉩니다.
/// - [AppHeader] MovieLog 로고, 검색 버튼
/// - [_GreetingSection] 오늘은 어떤 영화를 볼까요?
/// - [_FeaturedBanner] 추천 신작 배너
/// - [_PopularSection] 인기 영화 가로 목록
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// 배너 보조 문구 — Mock 데이터에 러닝타임·복수 장르가 없어 Figma 문구를 그대로 사용합니다.
  static const _featuredMeta = '로맨스 · 드라마 · 120분';

  /// 배너 배경 — 목록용 세로 포스터와 달리 가로형 이미지를 사용합니다.
  static const _featuredBackdrop =
      'assets/images/posters/hero_under_the_starlight.jpg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader.tab(title: 'MovieLog'),
      body: ListView(
        // Figma padding-bottom 96 = 하단 네비(80)에 가려지는 영역 + 여백 16.
        // 여기서는 네비가 본문을 덮지 않으므로 여백 16만 둡니다.
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const _GreetingSection(),
          // 중간 섹션 — padding 0 / 16 / 24 / 16
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: _FeaturedBanner(
              movie: movies.first,
              backdropAsset: _featuredBackdrop,
              meta: _featuredMeta,
            ),
          ),
          const _PopularSection(movies: popularMovies),
        ],
      ),
    );
  }
}

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
        style: textTheme.headlineMedium?.copyWith(
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
  const _FeaturedBanner({
    required this.movie,
    required this.backdropAsset,
    required this.meta,
  });

  final Movie movie;

  /// 배너 배경 이미지 (가로형)
  final String backdropAsset;

  /// 장르·러닝타임 문구 (예: 로맨스 · 드라마 · 120분)
  final String meta;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 534,
      // 뒤에 포스터 — 가로형 이미지를 가운데 기준으로 잘라 채웁니다.
      child: PosterImage(
        asset: backdropAsset,
        borderRadius: 24,
        overlays: [
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
                      style: textTheme.headlineMedium?.copyWith(
                        color: AppColors.onImage,
                        shadows: AppShadows.textOnImage,
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
                          shadows: AppShadows.textOnImage,
                        ),
                      ),
                    ),
                  ),
                  // 상세보기 — 308 x 48, gap 8, 배경 #4F378A, 아이콘 16.67 #FFFFFF
                  // box-shadow 0 2 4 -2 #0000001A, 0 4 6 -1 #0000001A
                  PillButton(
                    label: '상세보기',
                    iconAsset: 'assets/icons/banner_info_filled.svg',
                    iconSize: const Size.square(50 / 3),
                    color: colors.onPrimaryContainer,
                    foregroundColor: AppColors.onImage,
                    gap: 8,
                    shadows: AppShadows.raisedButton,
                    onPressed: () => context.push('/movies/${movie.id}'),
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
        shadows: AppShadows.card,
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
              style: textTheme.bodySmall?.copyWith(color: AppColors.onImage),
            ),
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
            style: textTheme.titleMedium?.copyWith(
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 4),
          // 아이콘 4.93 x 8
          SvgPicture.asset(
            'assets/icons/chevron_right.svg',
            width: 4.933,
            height: 8,
            colorFilter: ColorFilter.mode(
              colors.onPrimaryContainer,
              BlendMode.srcIn,
            ),
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
          // 배경 그림자 — 140 x 200, radius 16, #E6E0E9, box-shadow 0 1 2 #0000000D
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              height: 200,
              child: PosterImage(
                asset: movie.posterAsset,
                borderRadius: 16,
                hasShadow: true,
                overlays: [
                  // 순위 칩 — 24 x 26, 배경 #00000099, border 1px #FFFFFF1A
                  Positioned(
                    left: 8,
                    top: 8,
                    child: PosterBadge(
                      label: '$rank',
                      backgroundColor: AppColors.rankChip,
                      foregroundColor: AppColors.onImage,
                      borderColor: AppColors.rankChipOutline,
                    ),
                  ),
                ],
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
                    colorFilter: ColorFilter.mode(
                      colors.tertiary,
                      BlendMode.srcIn,
                    ),
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
