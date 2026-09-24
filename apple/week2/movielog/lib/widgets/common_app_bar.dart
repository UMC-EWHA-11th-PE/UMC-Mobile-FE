import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// 화면마다 반복되는 헤더를 공용 위젯으로 분리했습니다.
/// Figma 헤더: 388x64, 배경 #FAF9F5, padding-left 8, 뒤로가기 40x40 원형.
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    required this.title,
    this.onBack,
  });

  final String title;

  /// null이면 Navigator.maybePop을 호출합니다.
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(AppTheme.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      title: Text(title),
      // padding-left 8 + 40x40 버튼
      leadingWidth: 8 + 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          // 화살표 아이콘 컨테이너 16x16 — 공통 에셋 SVG 사용
          icon: SvgPicture.asset(
            'assets/icons/arrow_back.svg',
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(colors.onSurface, BlendMode.srcIn),
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          style: IconButton.styleFrom(shape: const CircleBorder()),
          tooltip: '뒤로가기',
        ),
      ),
    );
  }
}
