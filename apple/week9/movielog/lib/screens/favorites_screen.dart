import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../data/models/favorite_list_item.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../view_models/favorites_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_list_states.dart';
import '../widgets/movielog_button.dart';
import '../widgets/tmdb_poster_image.dart';

/// W9 내 즐겨찾기 화면 — 마이페이지에서 push, 하단 NavigationBar 없이 표시합니다.
///
/// - 불러오는 중: 로딩
/// - 빈 결과: 북마크 아이콘 + 안내
/// - 조회 오류: 안내 + 다시 시도
/// - 목록: 카드마다 TMDB 포스터·제목. TMDB 조회에 실패한 카드만 placeholder와 "정보 다시 불러오기"
///
/// 연결 순서: `/my/favorites` Route → 현재 세션의 [FavoritesViewModel] → 화면 initState에서 [FavoritesViewModel.refresh]
/// → 즐겨찾기 조회 → TMDB 정보 보충. build()에서는 조회하지 않습니다.
///
/// 카드를 누르면 [onOpenMovie]로 영화 상세에 가고, 돌아오면 상세에서 해제했을 수 있으므로 조용히 다시 조회합니다.
/// 아래로 당기면 목록을 새로고침합니다.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.onOpenMovie});

  /// 영화 상세로 이동 — Route가 `/movies/{id}`에 TmdbMovieDto를 extra로 넘깁니다.
  final Future<void> Function(TmdbMovieDto movie) onOpenMovie;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoritesViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: '내 즐겨찾기',
        titleStyle: AppTheme.appBarTitleBold,
      ),
      body: Consumer<FavoritesViewModel>(
        builder: (context, vm, _) => switch (vm.phase) {
          LoadPhase.idle || LoadPhase.loading => const MovieListLoading(),
          LoadPhase.empty => const _FavoritesEmpty(),
          LoadPhase.error => _FavoritesError(
            message: vm.errorMessage ?? '즐겨찾기를 불러오지 못했습니다.',
            onRetry: vm.refresh,
          ),
          LoadPhase.ready => RefreshIndicator(
            onRefresh: () => vm.refresh(silent: true),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 32, 22, 24),
              itemCount: vm.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final item = vm.items[index];
                final movie = item.movie;
                return _FavoriteCard(
                  item: item,
                  // 정보를 못 가져온 카드는 상세로 가지 않고 "정보 다시 불러오기"만 받습니다.
                  onTap: movie == null
                      ? null
                      : () async {
                          await widget.onOpenMovie(movie);
                          if (!mounted || vm.isDisposed) return;
                          // ViewModel이 같은 현재 세션인지 다시 확인한 뒤 목록을 맞춥니다.
                          await vm.refresh(silent: true);
                        },
                  onRetry: () => vm.retryMovie(item.movieId),
                );
              },
            ),
          ),
        },
      ),
    );
  }
}

/// 빈 결과 — 북마크 아이콘 24, 안내 2줄 (W9 내 즐겨찾기 빈 결과)
class _FavoritesEmpty extends StatelessWidget {
  const _FavoritesEmpty();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/detail_bookmark.svg',
            width: 20,
            height: 26,
            colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
          ),
          const SizedBox(height: 24),
          const Text('아직 즐겨찾기한 영화가 없습니다.', style: AppTheme.entryCardTitle),
          const SizedBox(height: 14),
          Text(
            '영화 상세에서 북마크를 눌러보세요.',
            style: AppTheme.ratingCardBody.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// 조회 오류 — 안내 + 다시 시도 (W9 내 즐겨찾기 조회 오류)
class _FavoritesError extends StatelessWidget {
  const _FavoritesError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.entryCardTitle.copyWith(
                fontSize: 15,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            MovieLogButton(label: '다시 시도', width: 210, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

/// 즐겨찾기 카드 — 평점 카드(W6-02)와 같은 흰 배경·테두리, 포스터 74 x 110
class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.item,
    required this.onTap,
    required this.onRetry,
  });

  final FavoriteListItem item;
  final VoidCallback? onTap;
  final VoidCallback onRetry;

  static const _posterSize = Size(74, 110);

  /// 예) 2026.09.06
  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${local.year}.${twoDigits(local.month)}.${twoDigits(local.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final movie = item.movie;
    final failed = movie == null && item.errorMessage != null;
    final loadingMovie = movie == null && !failed;
    final linkStyle = AppTheme.ratingCardScore.copyWith(fontSize: 13);

    return Material(
      color: AppColors.ratingCardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.ratingCardBorder, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox.fromSize(
                  size: _posterSize,
                  child: movie == null
                      // TMDB 정보가 없으면(불러오는 중·실패) 연보라 placeholder
                      ? Container(
                          key: const ValueKey('favorite-poster-placeholder'),
                          color: AppColors.retryIconBackground,
                        )
                      : TmdbPosterImage(
                          posterPath: movie.posterPath,
                          width: _posterSize.width,
                          height: _posterSize.height,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie?.title ?? '영화 #${item.movieId}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.ratingCardTitle,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        loadingMovie
                            ? '영화 정보를 불러오는 중입니다.'
                            : '${_formatDate(item.favorite.createdAt)} 추가',
                        style: AppTheme.ratingCardBody.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      Text('즐겨찾기한 영화', style: linkStyle),
                      if (failed) ...[
                        const SizedBox(height: 6),
                        // 이 카드만 TMDB를 다시 조회합니다.
                        Semantics(
                          button: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onRetry,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text('정보 다시 불러오기', style: linkStyle),
                            ),
                          ),
                        ),
                      ],
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
