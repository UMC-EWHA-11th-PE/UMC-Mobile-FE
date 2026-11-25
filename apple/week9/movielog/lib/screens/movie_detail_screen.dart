import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/movie_detail.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import '../view_models/favorite_detail_view_model.dart';
import '../widgets/app_header.dart';
import '../widgets/favorite_button.dart';
import '../widgets/movie_rating_indicator.dart';
import '../widgets/pill_button.dart';
import '../widgets/poster_image.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/svg_icon_button.dart';
import '../widgets/tag_chip.dart';
import '../widgets/tmdb_poster_image.dart';
import '../view_models/movie_detail_view_model.dart';

/// W3-03 영화 상세 화면입니다.
///
/// 5주차부터 [movieId](TMDB id)로 [MovieDetailViewModel]이 불러온 상세를 보여줍니다.
/// [detail]을 직접 받으면(홈 추천 신작 Mock) 그대로 보여줍니다.
///
/// 화면은 의미 단위로 나뉩니다.
/// - [_DetailHeader] 뒤로가기, Cinema Archive, 공유
/// - [_HeroPoster] 2:3 히어로 이미지
/// - [_InfoSection] 제목, 연도·장르·러닝타임, 별점, 장르 칩
/// - [_SynopsisSection] 시놉시스
/// - [_ActionBar] 하단 고정 즐겨찾기·평점 남기기 버튼
///
/// 7주차 — 평점 남기기가 [RatingDialog]를 열고, Dialog 안에서
/// [MovieDetailViewModel.createRating]으로 POST /v8/ratings(JWT)를 보냅니다.
/// 저장이 끝나 Dialog가 true를 돌려준 뒤에만 성공 Snackbar를 띄웁니다.
/// 이 화면은 로그인해야 열리므로 7주차의 학습용 회원가입 안내는 없앴습니다.
///
/// 9주차 — 즐겨찾기 버튼을 [FavoriteDetailViewModel]에 연결합니다. (POST·DELETE /v8/favorites)
/// 요청 중에는 버튼에 로딩을, 실패하면 이전 버튼 상태를 유지한 채 하단에 안내를 보여줍니다.
class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId, this.detail});

  /// TMDB 영화 id (경로의 movieId)
  final int? movieId;

  /// 이미 가진 상세 정보 — null이면 [MovieDetailViewModel]의 상태를 구독합니다.
  final MovieDetail? detail;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  /// 서버가 성공을 돌려줘 상태가 바뀐 경우에만 Snackbar를 띄웁니다.
  Future<void> _toggleFavorite() async {
    final changedTo = await context.read<FavoriteDetailViewModel>().toggle();
    if (!mounted || changedTo == null) return;
    _showMessage(changedTo ? '즐겨찾기에 추가했습니다.' : '즐겨찾기를 해제했습니다.');
  }

  /// 홈 추천 신작(Mock 영화)은 TMDB id가 아니므로 서버 즐겨찾기에 등록하지 않습니다.
  void _favoriteMockMovie() => _showMessage('예시 영화는 즐겨찾기할 수 없습니다.');

  Future<void> _rate() async {
    final viewModel = context.read<MovieDetailViewModel>();
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막습니다.
      builder: (_) => RatingDialog(
        // movieId는 ViewModel이 이미 갖고 있어 Dialog 밖으로 따로 넘기지 않습니다.
        onSubmit: (score, comment) async {
          await viewModel.createRating(score: score, comment: comment);
          if (viewModel.submitStatus != SubmitStatus.success) {
            throw WriteFailure(viewModel.submitMessage ?? '저장에 실패했습니다.');
          }
        },
      ),
    );
    // 저장 요청과 Snackbar는 서로 다른 비동기 경계 — await 뒤 mounted를 다시 확인합니다.
    // 취소(false)·뒤로가기(null)면 아무 것도 하지 않습니다.
    if (!mounted || saved != true) return;
    _showMessage('평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.');
  }

  /// 홈 추천 신작([widget.detail])은 Mock 영화라 TMDB id가 아니므로 서버에 평점을 남기지 않습니다.
  void _rateMockMovie() => _showMessage('예시 영화에는 평점을 남길 수 없습니다.');

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    if (detail != null) return _buildDetail(detail);

    return Consumer<MovieDetailViewModel>(
      builder: (context, viewModel, child) => switch (viewModel.status) {
        MovieDetailLoadStatus.idle ||
        MovieDetailLoadStatus.loading => const Scaffold(
          appBar: _DetailHeader(),
          body: Center(child: CircularProgressIndicator()),
        ),
        MovieDetailLoadStatus.error => Scaffold(
          appBar: const _DetailHeader(),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(viewModel.message ?? '영화 정보를 불러오지 못했어요.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.read<MovieDetailViewModel>().load(),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
        MovieDetailLoadStatus.success => _buildDetail(viewModel.detail!),
      },
    );
  }

  Widget _buildDetail(MovieDetail detail) {
    final isMock = widget.detail != null;
    final canRate = isMock || context.read<MovieDetailViewModel>().canRate;

    return Scaffold(
      appBar: const _DetailHeader(),
      body: ListView(
        children: [
          _HeroPoster(detail: detail),
          _InfoSection(detail: detail),
          _SynopsisSection(paragraphs: detail.synopsis),
        ],
      ),
      bottomNavigationBar: isMock
          ? _ActionBar(
              favoriteButton: FavoriteButton(
                isFavorite: false,
                textStyle: Theme.of(context).textTheme.titleSmall,
                onPressed: _favoriteMockMovie,
              ),
              onRate: _rateMockMovie,
            )
          : Consumer<FavoriteDetailViewModel>(
              builder: (context, favorite, _) => _ActionBar(
                favoriteButton: FavoriteButton(
                  isFavorite: favorite.isFavorite ?? false,
                  isLoading: favorite.isBusy,
                  textStyle: Theme.of(context).textTheme.titleSmall,
                  onPressed: favorite.canRequest ? _toggleFavorite : null,
                ),
                errorMessage: favorite.errorMessage,
                onRate: canRate ? _rate : null,
              ),
            ),
    );
  }
}

/// 상세 헤더 — 공통 [AppHeader]의 가운데 정렬형
/// 좌측 뒤로가기(32 x 32, left -8) · 가운데 Cinema Archive · 우측 공유(34 x 36)
class _DetailHeader extends StatelessWidget implements PreferredSizeWidget {
  const _DetailHeader();

  @override
  Size get preferredSize => const Size.fromHeight(AppHeader.height);

  void _back(BuildContext context) {
    // 앱을 상세 화면에서 바로 열었다면 돌아갈 화면이 없으므로 영화 목록으로 이동
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/movies');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppHeader(
      title: 'Cinema Archive',
      centerTitle: true,
      // Manrope 700 / 22 / 28, center, #6750A4
      titleStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.primary,
      ),
      // 좌측 아이콘 — 버튼 32 x 32, left -8, 아이콘 16 x 16 #6750A4
      leading: Transform.translate(
        offset: const Offset(-8, 0),
        child: SvgIconButton(
          asset: 'assets/icons/detail_arrow_back.svg',
          iconSize: const Size(16, 16),
          color: colors.primary,
          tooltip: '뒤로가기',
          onPressed: () => _back(context),
        ),
      ),
      // 우측 아이콘 — 버튼 34 x 36, 아이콘 18 x 20 #494551
      trailing: SvgIconButton(
        asset: 'assets/icons/detail_share.svg',
        iconSize: const Size(18, 20),
        color: colors.onSurfaceVariant,
        tooltip: '공유',
        onPressed: () {}, // 공유 기능은 아직 연결하지 않습니다.
      ),
    );
  }
}

/// 히어로 섹션 — 390 x 585 (2:3), 배경 #E3E2DF
/// Mock 영화는 에셋 이미지, TMDB 영화는 poster_path 이미지를 보여줍니다.
class _HeroPoster extends StatelessWidget {
  const _HeroPoster({required this.detail});

  final MovieDetail detail;

  @override
  Widget build(BuildContext context) {
    final heroAsset = detail.heroAsset;
    final backgroundColor = Theme.of(context).colorScheme.surfaceContainerHigh;

    return AspectRatio(
      aspectRatio: 2 / 3,
      child: heroAsset != null
          ? PosterImage(asset: heroAsset, backgroundColor: backgroundColor)
          : PosterImage(
              // poster_path가 없으면 TmdbPosterImage가 placeholder를 보여줍니다.
              image: TmdbPosterImage(
                posterPath: detail.posterPath,
                // 크기는 AspectRatio(2:3)가 정하므로 가득 채웁니다.
                width: double.infinity,
                height: double.infinity,
              ),
              backgroundColor: backgroundColor,
            ),
    );
  }
}

/// 인포 섹션 — 390 x 216, padding 24 / 16 / 40 / 16, gap 4
class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.detail});

  final MovieDetail detail;

  /// 2024 • 로맨스/드라마 • 124분 — 연도·장르가 없으면 빼고 표시합니다.
  String get _meta => [
    if (detail.year != null) '${detail.year}',
    if (detail.genres.isNotEmpty) detail.genres.join('/'),
    if (detail.runtimeMinutes != null) '${detail.runtimeMinutes}분',
  ].join(' • ');

  /// 1245 → 1,245
  static String _formatCount(int count) => count.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Manrope 400 / 14 / 20 / 0.25, #494551
    final captionStyle = textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 — Manrope 500 / 28 / 36, #1B1C1A
          Text(
            detail.title,
            style: textTheme.headlineMedium?.copyWith(
              color: AppColors.detailText,
            ),
          ),
          const SizedBox(height: 4),
          Text(_meta, style: captionStyle),
          const SizedBox(height: 4),
          // 별점 섹션 — padding-top 12, gap 4
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              height: 24,
              child: Row(
                children: [
                  // 평균 평점 — RatingBarIndicator로 읽기 전용 표시, 별 하나 16.67
                  MovieRatingIndicator(
                    rating: detail.rating,
                    itemSize: 50 / 3,
                    showValue: false,
                  ),
                  const SizedBox(width: 4),
                  // 4.5 마진 — padding-left 8, Manrope 500 / 16 / 24 / 0.15, #1B1C1A
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      detail.rating.toStringAsFixed(1),
                      style: textTheme.titleMedium?.copyWith(
                        letterSpacing: 0.15,
                        color: AppColors.detailText,
                      ),
                    ),
                  ),
                  if (detail.reviewCount != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${_formatCount(detail.reviewCount!)})',
                      style: captionStyle,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 장르 칩 — padding-top 20, gap 8
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in detail.tags)
                  // 칩 하나 — 높이 28, padding 4 / 12, 배경 #E3E2DF
                  // 글자 Manrope 500 / 14 / 20 / 0.1, #494551
                  TagChip(
                    label: tag,
                    backgroundColor: colors.surfaceContainerHigh,
                    foregroundColor: colors.onSurfaceVariant,
                    textStyle: textTheme.titleSmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 시놉시스 섹션 — padding 16, gap 8, border-top 1px #CBC4D2
/// 본문 문단 사이 gap 26
class _SynopsisSection extends StatelessWidget {
  const _SynopsisSection({required this.paragraphs});

  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Manrope 500 / 16 / 26 / 0.5, #494551
    const bodyStyle = AppTheme.synopsisBody;

    // Container는 테두리 두께(1)를 안쪽 여백에 더해 줘서 Figma 높이(563)와 맞습니다.
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Manrope 500 / 22 / 28, #1B1C1A
          Text(
            '시놉시스',
            style: textTheme.titleLarge?.copyWith(color: AppColors.detailText),
          ),
          const SizedBox(height: 8),
          // 줄거리(overview)가 없으면 안내 문구를 가운데에 표시
          if (paragraphs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('줄거리 정보가 없어요.', style: bodyStyle)),
            ),
          for (var i = 0; i < paragraphs.length; i++) ...[
            if (i > 0) const SizedBox(height: 26),
            Text(paragraphs[i], style: bodyStyle),
          ],
        ],
      ),
    );
  }
}

/// 하단 고정 액션 버튼 — 높이 81, padding 16, gap 8, 배경 #FAF9F5, border-top 1px #CBC4D2
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.favoriteButton,
    required this.onRate,
    this.errorMessage,
  });

  /// 즐겨찾기 버튼 — 상태는 [FavoriteDetailViewModel]이 정합니다.
  final Widget favoriteButton;

  /// 즐겨찾기 실패 안내 — 있으면 버튼 위에 보여주고, 버튼은 이전 상태 그대로입니다.
  final String? errorMessage;

  /// null이면 평점 남기기가 비활성 (영화 id를 모를 때)
  final VoidCallback? onRate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // 버튼 글자 — Manrope 500 / 14 / 20 / 0.1
    final labelStyle = Theme.of(context).textTheme.titleSmall;

    // Container는 테두리 두께(1)를 안쪽 여백에 더해 줘서 Figma 높이(81)와 맞습니다.
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (errorMessage != null) ...[
                _FavoriteErrorBox(message: errorMessage!),
                const SizedBox(height: 12),
              ],
              _buttons(colors, labelStyle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buttons(ColorScheme colors, TextStyle? labelStyle) {
    return Row(
      children: [
        // Figma 너비 176 : 174
        Expanded(
          flex: 176,
          // 즐겨찾기 상태는 제공된 북마크 아이콘(W3-REQ)을 사용합니다.
          child: favoriteButton,
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 174,
          // 채움형 — 배경 #6750A4, 아이콘 20 x 20 #FFFFFF, box-shadow 0 1 2 #0000000D
          child: PillButton(
            label: '평점 남기기',
            iconAsset: 'assets/icons/detail_rate_review.svg',
            iconSize: const Size(20, 20),
            color: colors.primary,
            foregroundColor: colors.onPrimary,
            textStyle: labelStyle,
            shadows: AppShadows.card,
            onPressed: onRate,
          ),
        ),
      ],
    );
  }
}

/// 즐겨찾기 실패 안내 — W9 "실패·기존 상태 유지" 시안의 연한 빨간 박스
/// 수치가 없어 시안 색으로 추정: 배경 #FFF2F0, 글자 #B3261E Manrope 400 / 13, radius 12
class _FavoriteErrorBox extends StatelessWidget {
  const _FavoriteErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.ratingDeleteButton,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: AppTheme.ratingCardBody.copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}
