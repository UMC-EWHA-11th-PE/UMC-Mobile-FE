import 'package:flutter/material.dart';

import '../widget/common_app_bar.dart';
import '../widget/profile_header.dart';
import '../widget/profile_stats.dart';
import '../widget/favorite_genres.dart';

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

              const SizedBox(height: 28),

              const ProfileStats(),

              const SizedBox(height: 28),

              Container(
                margin: const EdgeInsets.only(top: 4),
                child: const FavoriteGenres(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}