import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static const titleLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
  );

  static const titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.gray,
  );
}