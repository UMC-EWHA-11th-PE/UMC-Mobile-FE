import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// W1-01 내 프로필 화면입니다.
/// 1주차에는 라우팅을 구현하지 않고 MaterialApp.home을 바꿔 확인합니다.
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

/// Step 4. 프로필 이미지, 닉네임, 소개입니다.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // 프로필 이미지
        const CircleAvatar(
          radius: 56,
          backgroundImage: AssetImage(
            'assets/images/profile/profile_movielog.jpg',
          ),
        ),
        const SizedBox(height: 16),
        // 닉네임 옆에 SVG 아이콘 1개를 함께 표시합니다.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/star.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
              semanticsLabel: '별 아이콘',
            ),
            const SizedBox(width: 8),
            Text('무비러버', style: textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 8),
        // 소개
        Text(
          '좋아하는 영화를 기록하고 있어요',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Step 5. 데이터만 바꿔 재사용하는 통계 항목입니다.
class StatItem extends StatelessWidget {
  const StatItem({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}

/// StatItem을 가로로 배치한 통계 영역입니다.
class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        // Guided Practice에서 함께 배치한 첫 번째 항목입니다.
        Expanded(child: StatItem(label: '본 영화', value: '24')),
        SizedBox(width: 16),
        Expanded(child: StatItem(label: '평점', value: '4.2')),
        SizedBox(width: 16),
        Expanded(child: StatItem(label: '즐겨찾기', value: '58')),
      ],
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
