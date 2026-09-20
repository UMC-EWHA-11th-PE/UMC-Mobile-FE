import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/profile_stat.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common_app_bar.dart';

/// W1-01 내 프로필 화면입니다. Figma 프레임 390x844 기준으로 배치합니다.
/// 1주차에는 라우팅을 구현하지 않고 MaterialApp.home을 바꿔 확인합니다.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      // 헤더 — 390x64
      appBar: CommonAppBar(
        title: '내 프로필',
        actions: [
          IconButton(
            onPressed: () {}, // 1주차에는 동작을 연결하지 않습니다.
            // 단색 SVG는 colorFilter로 테마 색상을 입힙니다.
            icon: SvgPicture.asset(
              'assets/icons/person.svg',
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
              semanticsLabel: '내 정보',
            ),
          ),
        ],
      ),
      body: const SafeArea(top: false, child: ProfileBody()),
    );
  }
}

/// 메인 컨텐츠 — padding 24/16, 섹션 사이 gap 32
class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          ProfileHeader(),
          SizedBox(height: 32),
          ProfileStats(),
          SizedBox(height: 32),
          FavoriteGenres(),
        ],
      ),
    );
  }
}

/// Section - Profile Header Area — 358x294, gap 16
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // border — 128x128, 테두리 2px, 이미지 124x124
        Container(
          width: 128,
          height: 128,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(color: AppColors.avatarBorder, width: 2),
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/profile/profile_movielog.jpg',
              width: 124,
              height: 124,
              fit: BoxFit.cover,
              // 프로필 이미지가 없으면 기본 Icon을 보여줍니다.
              errorBuilder: (context, error, stackTrace) => Container(
                width: 124,
                height: 124,
                color: colors.primaryContainer,
                alignment: Alignment.center,
                child: Icon(
                  Icons.person,
                  size: 64,
                  color: colors.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 무비러버 + 설명 컨테이너 — 318 너비, gap 8
        SizedBox(
          width: 318,
          child: Column(
            children: [
              Text(
                '무비러버',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '매주 주말엔 영화관으로 출근하는 프로 관람객. 좋은 영화를 보고 기록하는 것을 좋아합니다.',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 버튼 마진 — 바깥 여백이므로 margin으로 줍니다. (padding-top 8)
        Container(
          margin: const EdgeInsets.only(top: 8),
          child: const EditProfileButton(),
        ),
      ],
    );
  }
}

/// 프로필 수정 버튼 — 127x42, radius 8, 테두리 1px
/// 1주차에는 보이기만 하고 동작을 연결하지 않습니다.
class EditProfileButton extends StatelessWidget {
  const EditProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {}, // 1주차에는 화면 이동을 연결하지 않습니다.
      child: const Text('프로필 수정'),
    );
  }
}

/// Section - Statistics Bento Grid — 358x86, gap 8
class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  static const List<ProfileStat> stats = [
    ProfileStat(label: '본 영화', value: '342'),
    ProfileStat(label: '평점', value: '4.2'),
    ProfileStat(label: '즐겨찾기', value: '58'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: stats
          .map(
            (stat) => Expanded(
              child: StatItem(label: stat.label, value: stat.value),
            ),
          )
          .toList(),
    );
  }
}

/// 데이터만 바꿔 재사용하는 통계 항목입니다.
/// Background+Border — 114x86, padding 16, radius 12, 테두리 1px
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        border: Border.all(color: colors.primaryContainer),
        borderRadius: BorderRadius.circular(AppTheme.statRadius),
      ),
      child: Column(
        children: [
          Text(value, textAlign: TextAlign.center, style: AppTheme.statValue),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// 선호하는 장르 섹션 — 358x72, gap 16
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
        // 태그 컨테이너 — gap 8
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genres.map((genre) => GenreChip(label: genre)).toList(),
        ),
      ],
    );
  }
}

/// 태그 칩 하나 — 66x32, padding 16/8, radius 9999
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
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: textTheme.bodySmall?.copyWith(color: AppColors.primaryDark),
      ),
    );
  }
}
