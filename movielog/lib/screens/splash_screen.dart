import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../widgets/movielog_button.dart';

/// 1주차 StartScreen 레이아웃을 재사용한 세션 확인 화면입니다.
/// - onRetry == null : 토큰 확인 중(initializing) → 인디케이터
/// - onRetry != null : 확인 실패(retryRequired) → 다시 시도 버튼
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              const Text(
                'FLUTTER 8주차',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 48),
              SvgPicture.asset(
                'assets/logos/movielog_logo.svg',
                width: 56,
                height: 56,
                semanticsLabel: 'MovieLog 로고',
              ),
              const SizedBox(height: 24),
              const Text(
                '영화의 순간을\n기록하세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.gray,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              // 1주차 '시작하기' 버튼 자리를 로딩/재시도 상태로 대체합니다.
              if (onRetry == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: CircularProgressIndicator(color: AppColors.violet),
                )
              else ...[
                Text(
                  message ?? '로그인 상태를 확인하지 못했어요.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.darkGray),
                ),
                const SizedBox(height: 12),
                MovieLogButton(
                  label: '다시 시도',
                  width: double.infinity,
                  onPressed: onRetry,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
