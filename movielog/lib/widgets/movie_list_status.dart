import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MovieListLoading extends StatelessWidget {
  const MovieListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class MovieListEmpty extends StatelessWidget {
  const MovieListEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('조건에 맞는 영화가 없습니다.'));
  }
}

class MovieListError extends StatelessWidget {
  const MovieListError({
    super.key,
    required this.onRetry,
    required this.onCancel,
  });

  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.lavenderGray,
              child: Icon(Icons.refresh, color: AppColors.violet, size: 32),
            ),
            const SizedBox(height: 12),
            const Text(
              '영화를 불러오지 못했어요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '네트워크 상태를 확인하고\n다시 시도해 주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.darkGray),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onCancel,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lavenderGray,
                      foregroundColor: AppColors.violet,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.violet,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('다시 시도'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
