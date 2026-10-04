import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const MovieLogApp());
}

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.violet),
        scaffoldBackgroundColor: AppColors.warmWhite,
      ),
      routerConfig: AppRouter.router,
    );
  }
}
