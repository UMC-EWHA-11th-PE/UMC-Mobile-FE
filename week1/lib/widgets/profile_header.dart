import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 48,
          backgroundImage: AssetImage(
            'assets/images/profile/profile_movielog.jpg',
          ),
        ),

        const SizedBox(height: 16),

        Text(
          '무비러버',
          style: AppTextStyles.titleMedium,
        ),

        const SizedBox(height: 8),

        Text(
          '좋아하는 영화를 기록하고 있어요',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}