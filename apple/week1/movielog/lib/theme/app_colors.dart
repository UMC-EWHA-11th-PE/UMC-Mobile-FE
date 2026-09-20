import 'package:flutter/material.dart';

/// Figma Design System에 정의된 원본 색상값입니다.
/// 위젯에서는 이 값을 직접 쓰지 않고 Theme.of(context).colorScheme을 통해 사용합니다.
class AppColors {
  const AppColors._();

  /// Primary — AppBar 제목, 프로필 수정 버튼
  static const Color primary = Color(0xFF6750A4);

  /// Primary 위에 올라가는 색
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// 시작하기 버튼 배경, 통계 숫자, 장르 Chip 텍스트
  static const Color primaryDark = Color(0xFF4F378A);

  /// 장르 Chip 배경, 통계 카드 테두리
  static const Color primaryContainer = Color(0xFFE9DDFF);

  /// 프로필 이미지 테두리
  static const Color avatarBorder = Color(0xFFD0BCFF);

  /// Surface — 화면 배경, AppBar 배경
  static const Color surface = Color(0xFFFAF9F5);

  /// 제목 텍스트 (무비러버, 선호하는 장르)
  static const Color onSurface = Color(0xFF1D1B20);

  /// 시작 화면 제목 — Figma가 프로필과 다른 값을 씁니다.
  static const Color onSurfaceStart = Color(0xFF1B1C1A);

  /// 보조 텍스트 (캡션, 설명, 통계 라벨)
  static const Color onSurfaceVariant = Color(0xFF494551);

  /// 통계 카드 배경
  static const Color surfaceContainer = Color(0xFFF5F3F0);

  /// 테두리
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC4D0);
}
