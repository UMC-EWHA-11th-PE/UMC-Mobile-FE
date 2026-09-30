import 'package:flutter/material.dart';

/// Figma Design System에 정의된 원본 색상값입니다.
/// 위젯에서는 이 값을 직접 쓰지 않고 Theme.of(context).colorScheme을 통해 사용합니다.
class AppColors {
  const AppColors._();

  /// Primary — AppBar 제목, 체크박스, 활성 가입하기 버튼, 로그인 링크
  static const Color primary = Color(0xFF6750A4);

  /// Primary 위에 올라가는 색
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// 비활성 가입하기 버튼 배경 (#CCC2DC)
  static const Color primaryDisabled = Color(0xFFCCC2DC);

  /// Surface — 화면 배경, 헤더 배경
  static const Color surface = Color(0xFFFAF9F5);

  /// 제목 텍스트 (닉네임, 이메일, 비밀번호 라벨, 약관 문구)
  static const Color onSurface = Color(0xFF1D1B20);

  /// 보조 텍스트 (환영 문구, 이미 계정이 있나요?)
  static const Color onSurfaceVariant = Color(0xFF494551);

  /// 입력창 배경
  static const Color surfaceContainer = Color(0xFFF5F3F0);

  /// 입력창 플레이스홀더
  static const Color placeholder = Color(0xFF7A7582);

  /// 입력창 테두리
  static const Color outlineVariant = Color(0xFFCBC4D2);

  /// 사용자가 입력한 텍스트 (플레이스홀더보다 진한 색)
  static const Color inputText = Color(0xFF211F26);

  /// 오류 상태 — 테두리, 느낌표 아이콘, 경고 문구
  static const Color error = Color(0xFFB3261E);

  /// 오류 상태 입력창 배경
  static const Color errorContainer = Color(0xFFFFDAD6);
}
