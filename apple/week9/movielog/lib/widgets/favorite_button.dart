import 'package:flutter/material.dart';

import 'pill_button.dart';

/// 영화 상세 즐겨찾기(북마크) 버튼 — 테두리형 [PillButton] (9주차)
///
/// 상태는 화면(ViewModel)이 정해서 넘기고, 버튼은 그대로 표시만 합니다.
/// - 등록 전: 빈 북마크 아이콘
/// - 등록 후: 채워진 북마크 아이콘
/// - 요청 중([isLoading]): 아이콘 자리에 로딩 표시, 눌러도 반응하지 않음
/// - 실패: ViewModel이 이전 상태를 유지하므로 버튼도 이전 모양 그대로
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.isLoading = false,
    this.textStyle,
  });

  final bool isFavorite;
  final bool isLoading;

  /// null이면 비활성 (예: 내 정보 확인 전)
  final VoidCallback? onPressed;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Opacity(
      opacity: onPressed == null && !isLoading ? 0.38 : 1,
      // 테두리형 — border 1px #6750A4, 아이콘 14 x 18
      child: PillButton(
        label: '즐겨찾기',
        iconAsset: isFavorite
            ? 'assets/icons/bookmark_filled.png'
            : 'assets/icons/detail_bookmark.svg',
        iconSize: const Size(14, 18),
        color: colors.primary,
        foregroundColor: colors.primary,
        outlined: true,
        textStyle: textStyle,
        selected: isFavorite,
        isLoading: isLoading,
        onPressed: onPressed,
      ),
    );
  }
}
