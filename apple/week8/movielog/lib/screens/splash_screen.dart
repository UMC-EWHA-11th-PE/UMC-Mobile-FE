import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../widgets/movielog_button.dart';

/// 스플래시 화면 — 1주차 시작 화면(StartScreen)의 로고·제목·설명 레이아웃을 재사용합니다.
///
/// 저장된 토큰을 `/members/me`로 확인하는 동안 빈 화면 대신 이 화면을 보여줍니다.
/// 1주차 하단의 '시작하기' 버튼 자리를 세션 확인 상태로 대체합니다.
/// - W8-01 세션 확인 중: [onRetry]가 null → 로딩 인디케이터
/// - W8-02 확인 실패·재시도: [onRetry]가 있음 → [message] + '다시 시도' 버튼
///
/// 두 상태가 같은 레이아웃이라 상태가 바뀌어도 화면이 튀지 않습니다.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.message, this.onRetry});

  /// 확인 실패 안내 문구. 없으면 기본 문구를 보여줍니다.
  final String? message;

  /// 세션 확인 다시 시도. null이면 확인 중(initializing) 상태입니다.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const SizedBox(height: 32),
                  // Manrope 500 / 11 / 16 / 0.55 (1주차와 같은 스타일)
                  Text('FLUTTER 8주차', style: textTheme.labelSmall),
                  const SizedBox(height: 64),
                  SvgPicture.asset(
                    'assets/logos/movielog_logo.svg',
                    width: 84,
                    height: 84,
                    semanticsLabel: 'MovieLog 로고',
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '영화의 순간을\n기록하세요',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.detailText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (onRetry == null)
                // 색은 colorScheme.primary(#6750A4)를 그대로 씁니다.
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    Text(
                      message ?? '로그인 상태를 확인하지 못했어요.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    MovieLogButton(
                      label: '다시 시도',
                      onPressed: onRetry,
                      width: double.infinity,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
