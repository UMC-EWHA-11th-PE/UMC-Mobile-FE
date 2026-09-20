import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// 프로필 화면을 확인할 때 아래 import와 home 값을 함께 바꿉니다.
import 'screens/profile_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const MovieLogApp());

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    // 1주차에는 화면 전환을 구현하지 않습니다.
    // 프로필 화면은 아래를 const ProfileScreen()으로 바꿔서 확인합니다.
    home: const ProfileScreen(),
  );
}

/// W1-00 시작 화면입니다. Figma 프레임 390x884 기준으로 배치합니다.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        // Figma 프레임(884px)에는 하단 인셋이 없으므로 수치를 그대로 재현합니다.
        bottom: false,
        // Main - Welcome Canvas: padding 32 / 16
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Section:margin — padding-top 32
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Column(
                  children: [
                    // Margin — padding-bottom 24
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text('FLUTTER 1주차', style: textTheme.labelSmall),
                    ),
                    // Illustration:margin — 128x128, padding-bottom 32
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: SvgPicture.asset(
                        'assets/logos/movielog_logo.svg',
                        width: 128,
                        height: 128,
                        semanticsLabel: 'MovieLog 로고',
                      ),
                    ),
                    // 타이포 — padding 좌우 8, gap 8
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Text(
                            '영화의 순간을\n기록하세요',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 하단 액션 버튼 — padding 좌우 16, 아래 24
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: AppTheme.buttonHeight,
                  child: ElevatedButton(
                    onPressed: () {}, // 1주차에는 화면 이동을 연결하지 않습니다.
                    child: const Text('시작하기'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
