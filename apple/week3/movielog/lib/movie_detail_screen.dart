import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'data/movie_detail.dart';
import 'theme/app_colors.dart';
import 'widgets/rating_dialog.dart';

/// W3-03 영화 상세 화면입니다.
///
/// 화면은 의미 단위로 나뉩니다.
/// - [_DetailHeader] 뒤로가기, Cinema Archive, 공유
/// - [_HeroPoster] 2:3 히어로 이미지
/// - [_InfoSection] 제목, 연도·장르·러닝타임, 별점, 장르 칩
/// - [_SynopsisSection] 시놉시스
/// - [_ActionBar] 하단 고정 즐겨찾기·평점 남기기 버튼
class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId});

  final int? movieId;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  /// 즐겨찾기 여부 — 실제 API 연결은 8주차, 3주차에서는 화면 내부 상태만 바꿉니다.
  bool _bookmarked = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _toggleBookmark() {
    setState(() => _bookmarked = !_bookmarked);
    _showMessage(_bookmarked ? '즐겨찾기에 추가했습니다.' : '즐겨찾기를 해제했습니다.');
  }

  Future<void> _rate() async {
    final rating = await showDialog<double>(
      context: context,
      builder: (context) => const RatingDialog(),
    );
    // 바깥을 눌러 닫았거나 별을 고르지 않고 확인을 누른 경우
    if (!mounted || rating == null || rating < 0.5) return;
    _showMessage('평점 ${rating.toStringAsFixed(1)}점을 남겼습니다.');
  }

  @override
  Widget build(BuildContext context) {
    final detail = findMovieDetailById(widget.movieId);

    if (detail == null) {
      return const Scaffold(
        appBar: _DetailHeader(),
        body: Center(child: Text('영화를 찾을 수 없습니다.')),
      );
    }

    return Scaffold(
      appBar: const _DetailHeader(),
      body: ListView(
        children: [
          _HeroPoster(asset: detail.heroAsset),
          _InfoSection(detail: detail),
          if (detail.synopsis.isNotEmpty)
            _SynopsisSection(paragraphs: detail.synopsis),
        ],
      ),
      bottomNavigationBar: _ActionBar(
        bookmarked: _bookmarked,
        onBookmark: _toggleBookmark,
        onRate: _rate,
      ),
    );
  }
}

/// 상세 헤더 — 높이 64, padding 0 / 16
/// 좌측 뒤로가기(32 x 32, left -8) · 가운데 Cinema Archive · 우측 공유(34 x 36)
class _DetailHeader extends StatelessWidget implements PreferredSizeWidget {
  const _DetailHeader();

  static const double _height = 64;

  /// Figma 좌·우 아이콘 영역 너비 (32.02 + 293.96 + 32.02 = 358)
  static const double _sideWidth = 32.02;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

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

    return ColoredBox(
      color: colors.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // 좌측 아이콘 — 버튼 32 x 32, padding 8, left -8, 아이콘 16 x 16 #6750A4
              SizedBox(
                width: _sideWidth,
                height: 40,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: const Offset(-8, 0),
                    child: _HeaderIconButton(
                      asset: 'assets/icons/detail_arrow_back.svg',
                      iconSize: const Size(16, 16),
                      color: colors.primary,
                      tooltip: '뒤로가기',
                      onPressed: () => _back(context),
                    ),
                  ),
                ),
              ),
              // 텍스트 — Manrope 700 / 22 / 28, center, #6750A4
              Expanded(
                child: Text(
                  'Cinema Archive',
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ),
              // 우측 아이콘 — 버튼 34 x 36, padding 8, 아이콘 18 x 20 #494551
              SizedBox(
                width: _sideWidth,
                height: 36,
                child: OverflowBox(
                  maxWidth: 34,
                  child: _HeaderIconButton(
                    asset: 'assets/icons/detail_share.svg',
                    iconSize: const Size(18, 20),
                    color: colors.onSurfaceVariant,
                    tooltip: '공유',
                    onPressed: () {}, // 공유 기능은 아직 연결하지 않습니다.
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

/// 헤더 아이콘 버튼 — radius 9999, padding 8
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.asset,
    required this.iconSize,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final String asset;
  final Size iconSize;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: SvgPicture.asset(
        asset,
        width: iconSize.width,
        height: iconSize.height,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
      padding: const EdgeInsets.all(8),
      constraints: BoxConstraints.tightFor(
        width: iconSize.width + 16,
        height: iconSize.height + 16,
      ),
      style: IconButton.styleFrom(
        shape: const StadiumBorder(),
        // 기본 48x48 터치 영역 여백을 없애 Figma 크기에 맞춤
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      tooltip: tooltip,
    );
  }
}

/// 히어로 섹션 — 390 x 585 (2:3), 배경 #E3E2DF
class _HeroPoster extends StatelessWidget {
  const _HeroPoster({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// 인포 섹션 — 390 x 216, padding 24 / 16 / 40 / 16, gap 4
class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.detail});

  final MovieDetail detail;

  /// 2024 • 로맨스/드라마 • 124분
  String get _meta => [
    '${detail.year}',
    detail.genres.join('/'),
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
    final captionStyle = textTheme.bodySmall?.copyWith(
      fontSize: 14,
      height: 20 / 14,
      letterSpacing: 0.25,
      fontWeight: FontWeight.w400,
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
            style: textTheme.titleMedium?.copyWith(
              fontSize: 28,
              height: 36 / 28,
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
                  _StarRating(rating: detail.rating),
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
              children: [for (final tag in detail.tags) _TagChip(label: tag)],
            ),
          ),
        ],
      ),
    );
  }
}

/// 별 5개 — 별 하나 16.67 x 15.83, 간격 없음, #6750A4
/// 1점 단위는 채운 별, 0.5점 이상 남으면 반 별, 나머지는 빈 별
class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating});

  final double rating;

  String _assetFor(int index) {
    final remain = rating - index;
    if (remain >= 1) return 'assets/icons/rating_star_filled.svg';
    if (remain >= 0.5) return 'assets/icons/rating_star_half.svg';
    return 'assets/icons/rating_star_outline.svg';
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Semantics(
      label: '별점 ${rating.toStringAsFixed(1)}점',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++)
            SvgPicture.asset(
              _assetFor(i),
              width: 50 / 3,
              height: 95 / 6,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
        ],
      ),
    );
  }
}

/// 장르 칩 — 높이 28, radius 9999, padding 4 / 12, 배경 #E3E2DF
/// 글자 Manrope 500 / 14 / 20 / 0.1, #494551
class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: ShapeDecoration(
        color: colors.surfaceContainerHigh,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: textTheme.titleMedium?.copyWith(
          fontSize: 14,
          height: 20 / 14,
          letterSpacing: 0.1,
          color: colors.onSurfaceVariant,
        ),
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
    final bodyStyle = textTheme.titleMedium?.copyWith(
      height: 26 / 16,
      letterSpacing: 0.5,
      color: colors.onSurfaceVariant,
    );

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
    required this.bookmarked,
    required this.onBookmark,
    required this.onRate,
  });

  final bool bookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
          child: Row(
            children: [
              // Figma 너비 176 : 174
              Expanded(
                flex: 176,
                child: _ActionButton(
                  label: '즐겨찾기',
                  icon: bookmarked
                      ? 'assets/icons/detail_bookmark_filled.svg'
                      : 'assets/icons/detail_bookmark.svg',
                  iconSize: const Size(14, 18),
                  filled: false,
                  selected: bookmarked,
                  onPressed: onBookmark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 174,
                child: _ActionButton(
                  label: '평점 남기기',
                  icon: 'assets/icons/detail_rate_review.svg',
                  iconSize: const Size(20, 20),
                  filled: true,
                  onPressed: onRate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 액션 버튼 하나 — 높이 48, radius 9999, gap 4, 글자 Manrope 500 / 14 / 20 / 0.1
/// 테두리형: border 1px #6750A4, 아이콘·글자 #6750A4
/// 채움형: 배경 #6750A4, 아이콘·글자 #FFFFFF, box-shadow 0 1 2 #0000000D
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.iconSize,
    required this.filled,
    required this.onPressed,
    this.selected,
  });

  final String label;
  final String icon;
  final Size iconSize;
  final bool filled;
  final VoidCallback onPressed;

  /// 토글 버튼이면 현재 상태 (즐겨찾기)
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = filled ? colors.onPrimary : colors.primary;

    return Semantics(
      toggled: selected,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          shadows: filled
              ? const [
                  BoxShadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Color(0x0D000000),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: filled ? colors.primary : Colors.transparent,
          shape: StadiumBorder(
            side: filled ? BorderSide.none : BorderSide(color: colors.primary),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    icon,
                    width: iconSize.width,
                    height: iconSize.height,
                    colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      height: 20 / 14,
                      letterSpacing: 0.1,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
