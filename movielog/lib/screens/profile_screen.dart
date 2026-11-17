import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/member_info.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';
import '../widgets/stat_item.dart';

/// 마이페이지: GET me로 받은 이메일·닉네임·가입일을 표시하고,
/// 앱바 오른쪽 로그아웃, 프로필 수정 진입을 제공합니다.
/// (사진·통계·장르는 기존 디자인 예시입니다.)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final member = auth.member;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        centerTitle: false,
        title: const Text('내 프로필', style: AppTextStyles.titleLarge),
        actions: [
          TextButton(
            onPressed: auth.storageCleanupInProgress
                ? null
                : () => context.read<AuthViewModel>().logout(),
            child: const Text('로그아웃'),
          ),
        ],
      ),
      body: SafeArea(
        child: switch ((member, auth.memberStatus)) {
          // 내 정보 로딩 실패 → 재시도 (네트워크 실패로 로그아웃하지 않음)
          (null, MemberLoadStatus.error) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('내 정보를 불러오지 못했어요.'),
                  const SizedBox(height: 12),
                  MovieLogButton(
                    label: '다시 시도',
                    onPressed: () => context
                        .read<AuthViewModel>()
                        .loadMember(force: true),
                  ),
                ],
              ),
            ),
          // 내 정보 로딩 중
          (null, _) => const Center(child: CircularProgressIndicator()),
          (final MemberInfo m, _) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ProfileBody(member: m),
            ),
        },
      ),
    );
  }
}

class ProfileBody extends StatelessWidget {
  const ProfileBody({super.key, required this.member});

  final MemberInfo member;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileHeader(member: member),
        const SizedBox(height: 24),
        const ProfileStats(),
        const SizedBox(height: 32),
        const FavoriteGenres(),
      ],
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.member});

  final MemberInfo member;

  String _joinedText(DateTime date) {
    final local = date.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return '${local.year}.$mm.$dd 가입';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          const CircleAvatar(
            radius: 56,
            backgroundImage: AssetImage(
              'assets/images/profile/profile_movielog.jpg',
            ),
          ),
          const SizedBox(height: 16),
          Text(member.nickname, style: AppTextStyles.titleLarge),
          const SizedBox(height: 4),
          Text(member.email, style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text(_joinedText(member.createdAt), style: AppTextStyles.bodySmall),
          const SizedBox(height: 16),
          const EditProfileButton(),
        ],
      ),
    );
  }
}

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: StatItem(label: '본 영화', value: '342')),
        SizedBox(width: 12),
        Expanded(child: StatItem(label: '평점', value: '4.2')),
        SizedBox(width: 12),
        Expanded(child: StatItem(label: '즐겨찾기', value: '58')),
      ],
    );
  }
}

class FavoriteGenres extends StatelessWidget {
  const FavoriteGenres({super.key});

  static const genres = ['드라마', 'SF', '애니메이션'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('선호하는 장르', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genres
              .map(
                (genre) => Chip(
                  label: Text(
                    genre,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.violet,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: AppColors.violet.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class EditProfileButton extends StatelessWidget {
  const EditProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => context.push('/my/profile/edit'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.violet,
        side: const BorderSide(color: AppColors.violet),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: const Text('프로필 수정'),
    );
  }
}
