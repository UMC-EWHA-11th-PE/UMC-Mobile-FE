import 'package:flutter/material.dart';

/// 여러 화면이 함께 쓰는 공용 버튼 — 높이 44, radius 12
///
/// 상태는 화면(ViewModel)이 정해서 넘기고, 버튼은 그대로 표시만 합니다.
/// - 기본: [onPressed]가 있고 [isLoading]이 false
/// - 통신 중: [isLoading]이 true — 비활성 배경 + 가운데 로딩 표시
/// - 비활성: [onPressed]가 null
///
/// 너비는 [width]로 정합니다.
/// - null: 글자 길이에 맞춘 가변 너비 (예: 중복 확인 버튼)
/// - double.infinity: 부모가 허락하는 최대 너비 (예: 가입하기 버튼)
/// - 숫자: 고정 너비
///
/// 색은 테마의 elevatedButtonTheme(primary / primaryDisabled / onPrimary)을 따릅니다.
class MovieLogButton extends StatelessWidget {
  const MovieLogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  static const double _height = 44;

  bool get _disabled => isLoading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      height: _height,
      child: ElevatedButton(
        onPressed: _disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          // 테마 기본값(높이 56, 상하 패딩 16)을 44 높이에 맞게 줄입니다.
          minimumSize: const Size(0, _height),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // 통신 중에는 글자와 로딩 표시 중 하나만 그립니다.
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.onPrimary,
                ),
              )
            : Text(label),
      ),
    );
  }
}
