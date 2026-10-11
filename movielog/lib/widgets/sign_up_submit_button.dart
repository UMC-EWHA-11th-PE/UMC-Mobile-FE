import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SignUpSubmitButton extends StatelessWidget {
  const SignUpSubmitButton({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          backgroundColor: AppColors.violet,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.lavenderGray,
          disabledForegroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        child: Text('가입하기'),
      ),
    );
  }
}
