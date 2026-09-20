import 'package:flutter/material.dart';

/// 화면마다 반복되는 AppBar를 공용 위젯으로 분리했습니다.
/// 색상과 높이는 AppTheme의 appBarTheme을 따릅니다.
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: leading,
      actions: actions,
    );
  }
}
