import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';

class StatItem extends StatelessWidget {
  final String label;
  final String value;

  const StatItem({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.violet.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall,
            ),

            const SizedBox(height: 6),

            Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.violet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}