import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 화면마다 반복되는 AppBar를 공용 위젯으로 분리했습니다.
/// 높이 64, 좌우 여백 16, 제목 색상은 AppTheme의 appBarTheme을 따릅니다.
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(AppTheme.appBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: leading,
      actions: actions,
    );
  }
}
