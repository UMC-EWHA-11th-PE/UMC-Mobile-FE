import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_text_styles.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // MovieLog 로고
              SvgPicture.asset(
                'assets/logos/movielog_logo.svg',
                width: 72,
                height: 72,
                semanticsLabel: 'MovieLog 로고',
              ),

              const SizedBox(height: 24),

              // 제목
              Text(
                '영화의 순간을 기록하세요',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge,
              ),

              const SizedBox(height: 12),

              // 설명
              Text(
                'MovieLog와 함께 나만의 영화 기록을 만들어보세요.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),

              const Spacer(),

              // 시작하기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('시작하기'),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}