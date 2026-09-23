import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Figma Design System을 Flutter Theme로 옮긴 결과입니다.
/// MaterialApp의 theme에 AppTheme.light를 연결해서 사용합니다.
class AppTheme {
  const AppTheme._();

  /// 8px을 기본 간격 단위로 사용합니다.
  static const double spacingUnit = 8;

  /// 입력창, 가입하기 버튼의 모서리 반경입니다. (Figma: 8px)
  static const double radius = 8;

  /// 체크박스의 모서리 반경입니다. (Figma: 4px)
  static const double checkboxRadius = 4;

  /// 체크박스 한 변의 길이입니다. (Figma: 26px)
  static const double checkboxSize = 26;

  /// 가입하기 버튼의 높이입니다. (Figma: 56px)
  static const double buttonHeight = 56;

  /// 헤더 높이입니다. (Figma: 64px)
  static const double appBarHeight = 64;

  /// 입력창의 높이입니다. (Figma: 42px)
  static const double inputHeight = 42;

  static final ColorScheme _lightColorScheme = const ColorScheme.light().copyWith(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    surfaceContainer: AppColors.surfaceContainer,
    outlineVariant: AppColors.outlineVariant,
    error: AppColors.error,
    errorContainer: AppColors.errorContainer,
  );

  /// Figma Typography를 그대로 옮긴 TextTheme입니다.
  /// height는 line-height / font-size로 계산합니다.
  static const TextTheme _textTheme = TextTheme(
    // 회원가입 (헤더 제목) — Manrope 500 / 22 / 28 / 0
    titleLarge: TextStyle(
      fontSize: 22,
      height: 28 / 22,
      letterSpacing: 0,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurface,
    ),
    // 라벨, 약관 문구, 버튼, 환영 문구 — Manrope 500 / 16 / 24 / 0
    titleMedium: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      letterSpacing: 0,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurface,
    ),
    // 입력 텍스트, 플레이스홀더 — Manrope 500 / 16 / 100%
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1,
      letterSpacing: 0,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurface,
    ),
    // 오류 안내 문구 — Manrope 500 / 12 / 16
    bodySmall: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      letterSpacing: 0,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurfaceVariant,
    ),
    // 가입하기 — Manrope 500 / 16 / 24 / 0
    labelLarge: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      letterSpacing: 0,
      fontWeight: FontWeight.w500,
    ),
  );

  static ThemeData get light {
    final colors = _lightColorScheme;

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: appBarHeight,
        titleTextStyle: _textTheme.titleLarge?.copyWith(color: colors.primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: AppColors.primaryDisabled,
          disabledForegroundColor: colors.onPrimary,
          // box-shadow: 0px 1px 2px 0px #0000000D
          elevation: 1,
          shadowColor: const Color(0x0D000000),
          minimumSize: const Size(0, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: _textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(colors.onPrimary),
        side: BorderSide(color: colors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(checkboxRadius),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainer,
        isDense: true,
        // padding 9 / 16 / 8 / 16 — 텍스트 24 + 상하 패딩 + 테두리로 42px을 맞춥니다.
        contentPadding: const EdgeInsets.fromLTRB(16, 9, 16, 8),
        hintStyle: _textTheme.bodyLarge?.copyWith(color: AppColors.placeholder),
        errorStyle: _textTheme.bodySmall?.copyWith(color: colors.error),
        border: _inputBorder(colors.outlineVariant),
        enabledBorder: _inputBorder(colors.outlineVariant),
        focusedBorder: _inputBorder(colors.primary),
        errorBorder: _inputBorder(colors.error),
        focusedErrorBorder: _inputBorder(colors.error),
        suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 24),
      ),
    );
  }

  /// border: 1px solid, radius 8px
  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: BorderSide(color: color),
  );
}
