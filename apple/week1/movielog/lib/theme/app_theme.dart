import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Figma Design System을 Flutter Theme로 옮긴 결과입니다.
/// MaterialApp의 theme에 AppTheme.light를 연결해서 사용합니다.
class AppTheme {
  const AppTheme._();

  /// 8px을 기본 간격 단위로 사용합니다.
  static const double spacingUnit = 8;

  /// Card, Input, 프로필 수정 버튼의 모서리 반경입니다.
  static const double radius = 8;

  /// 시작하기 버튼의 모서리 반경입니다. (Figma: 16px)
  static const double buttonRadius = 16;

  /// 시작하기 버튼의 높이입니다. (Figma: 56px)
  static const double buttonHeight = 56;

  /// 프로필 수정 버튼의 높이입니다. (Figma: 42px)
  static const double outlinedButtonHeight = 42;

  /// AppBar 높이입니다. (Figma 헤더: 64px)
  static const double appBarHeight = 64;

  /// 통계 카드의 모서리 반경입니다. (Figma: 12px)
  static const double statRadius = 12;

  static final ColorScheme _lightColorScheme = const ColorScheme.light().copyWith(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.primaryDark,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    surfaceContainer: AppColors.surfaceContainer,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
  );

  /// Figma Typography를 그대로 옮긴 TextTheme입니다.
  /// height는 line-height / font-size로 계산합니다.
  static const TextTheme _textTheme = TextTheme(
    // FLUTTER 1주차 — Manrope 500 / 11 / 16 / 0.55
    labelSmall: TextStyle(
      fontSize: 11,
      height: 16 / 11,
      letterSpacing: 0.55,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurfaceVariant,
    ),
    // 영화의 순간을 기록하세요 — Manrope 500 / 28 / 36 / 0
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 36 / 28,
      letterSpacing: 0,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurfaceStart,
    ),
    // 내 프로필, 무비러버 — Manrope 500 / 22 / 28 / 0
    titleLarge: TextStyle(
      fontSize: 22,
      height: 28 / 22,
      letterSpacing: 0,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurface,
    ),
    // 선호하는 장르, 설명, 프로필 수정 — Manrope 500 / 16 / 24 / 0
    titleMedium: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      letterSpacing: 0,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurface,
    ),
    // 보고 싶은 영화부터… — Manrope 500 / 14 / 20 / 0.25
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      letterSpacing: 0.25,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurface,
    ),
    // 통계 라벨, 장르 Chip — Manrope 500 / 12 / 16 / 0
    bodySmall: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      letterSpacing: 0,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurfaceVariant,
    ),
    // 시작하기 — Manrope 500 / 14 / 20 / 0.1
    labelLarge: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      letterSpacing: 0.1,
      fontWeight: FontWeight.w500,
    ),
  );

  /// 통계 숫자 — Manrope 700 / 22 / 28 / 0
  static const TextStyle statValue = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryDark,
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
        centerTitle: false,
        toolbarHeight: appBarHeight,
        titleSpacing: 16,
        titleTextStyle: _textTheme.titleLarge?.copyWith(color: colors.primary),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          minimumSize: const Size(0, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          textStyle: _textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          minimumSize: const Size(0, outlinedButtonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          textStyle: _textTheme.titleMedium,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
