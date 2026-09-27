import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

class FavoriteGenres extends StatelessWidget {
  const FavoriteGenres({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '선호 장르',
          style: AppTextStyles.titleMedium,
        ),

        const SizedBox(height: 12),

        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              label: Text('드라마'),
            ),
            Chip(
              label: Text('SF'),
            ),
            Chip(
              label: Text('애니메이션'),
            ),
          ],
        ),
      ],
    );
  }
}