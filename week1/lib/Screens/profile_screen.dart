import 'package:flutter/material.dart';

import '../widgets/common_app_bar.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats.dart';
import '../widgets/favorite_genres.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: '내 프로필',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ProfileHeader(),

              const SizedBox(height: 32),

              const ProfileStats(),

              const SizedBox(height: 32),

              const FavoriteGenres(),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('프로필 수정'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}