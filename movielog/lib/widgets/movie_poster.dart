import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MoviePoster extends StatelessWidget {
  const MoviePoster({super.key, required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppColors.lavenderGray,
          child: const Center(child: Icon(Icons.movie, color: AppColors.white)),
        );
      },
    );
  }
}
