import 'package:flutter/material.dart';

/// Figma Design System에 정의된 원본 색상값입니다.
/// 위젯에서는 이 값을 직접 쓰지 않고 Theme.of(context).colorScheme을 통해 사용합니다.
class AppColors {
  const AppColors._();

  /// Primary — 로고, 버튼, 강조 텍스트
  static const Color primary = Color(0xFF6750A4);

  /// Primary 위에 올라가는 색
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Primary의 옅은 배경 — 장르 Chip 등
  static const Color primaryContainer = Color(0xFFEADDFF);
  static const Color onPrimaryContainer = Color(0xFF21005D);

  /// Surface — 화면 배경
  static const Color surface = Color(0xFFFAF9F5);
  static const Color onSurface = Color(0xFF1C1B1F);

  /// 보조 텍스트
  static const Color onSurfaceVariant = Color(0xFF49454F);

  /// 통계 카드 배경
  static const Color surfaceContainer = Color(0xFFF3F1EC);

  /// 테두리
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);
}
