import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Figma Design System을 Flutter Theme로 옮긴 결과입니다.
/// MaterialApp의 theme에 AppTheme.light를 연결해서 사용합니다.
class AppTheme {
  const AppTheme._();

  /// 8px을 기본 간격 단위로 사용합니다.
  static const double spacingUnit = 8;

  /// Card, Button, Input의 모서리 반경입니다.
  static const double radius = 8;

  static final ColorScheme _lightColorScheme = const ColorScheme.light().copyWith(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    surfaceContainer: AppColors.surfaceContainer,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
  );

  static ThemeData get light {
    final colors = _lightColorScheme;

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ).apply(
        bodyColor: colors.onSurface,
        displayColor: colors.onSurface,
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
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.outlineVariant),
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
