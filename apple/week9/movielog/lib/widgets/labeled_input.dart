import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// 라벨 + 입력창 묶음 — 라벨 Manrope 600 / 13, 입력창과 gap 6 (W8 로그인·프로필 수정)
class LabeledInput extends StatelessWidget {
  const LabeledInput({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            height: 20 / 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// W8 입력창 꾸밈 — 글자 14, 오류여도 배경은 그대로 두고 테두리만 빨갛게 바꿉니다.
///
/// 테마 기본값은 오류일 때 배경을 #FFDAD6으로 칠하지만 W8 Figma는 흰 배경 + 빨간 테두리입니다.
InputDecoration movieLogInputDecoration(
  BuildContext context, {
  String? hint,
  bool hasError = false,
  Color fillColor = AppColors.inputBackground,
}) {
  final textTheme = Theme.of(context).textTheme;
  final errorBorder = hasError
      ? OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        )
      : null;
  return InputDecoration(
    hintText: hint,
    hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.placeholder),
    fillColor: fillColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: errorBorder,
    focusedBorder: errorBorder,
  );
}

/// W8 입력 글자 — Manrope 400 / 14
TextStyle? movieLogInputTextStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: AppColors.inputText);
