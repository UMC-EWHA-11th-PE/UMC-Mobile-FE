import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LoginPrompt extends StatelessWidget {
  const LoginPrompt({super.key, this.onLoginTap});

  final VoidCallback? onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '이미 계정이 있나요?',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.darkGray,
            fontWeight: FontWeight.w500,
          ),
        ),

        TextButton(
          onPressed: onLoginTap ?? () {},
          style: TextButton.styleFrom(
            foregroundColor: AppColors.violet,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '로그인',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
