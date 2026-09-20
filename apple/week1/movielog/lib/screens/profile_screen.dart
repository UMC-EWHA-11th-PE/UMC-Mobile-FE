import 'package:flutter/material.dart';

/// W1-01 내 프로필 화면입니다.
/// 1주차에는 화면 전환을 연결하지 않고 MaterialApp.home을 바꿔 확인합니다.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
      ),
      body: const SafeArea(child: ProfileBody()),
    );
  }
}

/// AppBar 아래 본문 전체입니다.
class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          ProfileHeader(),
          SizedBox(height: 24),
          EditProfileButton(),
          SizedBox(height: 32),
          ProfileStats(),
          SizedBox(height: 32),
          FavoriteGenres(),
        ],
      ),
    );
  }
}

/// 프로필 사진, 닉네임, 소개글입니다.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const CircleAvatar(
          radius: 56,
          backgroundImage: AssetImage('assets/images/profile/profile_movielog.jpg'),
        ),
        const SizedBox(height: 16),
        Text('무비러버', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          '매주 주말엔 영화관으로 출근하는 프로 관람객. 좋은 영화를 보고 기록하는 것을 좋아합니다.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// 프로필 수정 버튼입니다. 1주차에는 동작을 연결하지 않습니다.
class EditProfileButton extends StatelessWidget {
  const EditProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton(
        onPressed: () {}, // 1주차에는 화면 이동을 연결하지 않습니다.
        child: const Text('프로필 수정'),
      ),
    );
  }
}

/// 본 영화 / 평점 / 즐겨찾기 통계입니다.
class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: ProfileStatItem(label: '본 영화', value: '342')),
        SizedBox(width: 16),
        Expanded(child: ProfileStatItem(label: '평점', value: '4.2')),
        SizedBox(width: 16),
        Expanded(child: ProfileStatItem(label: '즐겨찾기', value: '58')),
      ],
    );
  }
}

/// 통계 항목 하나입니다.
class ProfileStatItem extends StatelessWidget {
  const ProfileStatItem({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(color: colors.primary),
          ),
        ],
      ),
    );
  }
}

/// 선호하는 장르 목록입니다.
class FavoriteGenres extends StatelessWidget {
  const FavoriteGenres({super.key});

  static const List<String> genres = ['드라마', 'SF', '애니메이션'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('선호하는 장르', style: textTheme.titleMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final genre in genres) GenreChip(label: genre),
          ],
        ),
      ],
    );
  }
}

/// 장르 Chip 하나입니다.
class GenreChip extends StatelessWidget {
  const GenreChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: textTheme.bodySmall?.copyWith(color: colors.onPrimaryContainer),
      ),
    );
  }
}
