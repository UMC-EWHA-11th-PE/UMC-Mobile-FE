import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/profile_stat.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/learning_member_session.dart';
import '../widgets/app_header.dart';
import '../widgets/tag_chip.dart';

/// 마이 탭 — 1주차 W1-01 내 프로필 화면을 가져왔습니다.
///
/// 8주차(W8-06) — 닉네임·이메일은 `/members/me`로 받은 [AuthViewModel.member]를 보여주고,
/// 헤더 오른쪽에 로그아웃 버튼을 둡니다. 통계·선호 장르는 아직 학습용 고정 값입니다.
///
/// 화면은 의미 단위로 나뉩니다.
/// - [AppHeader] 내 프로필, 로그아웃 버튼
/// - [_ProfileHeader] 프로필 사진, 닉네임, 이메일, 프로필 수정 버튼
/// - [_ProfileStats] 본 영화·평점·즐겨찾기 통계
/// - [_FavoriteGenres] 선호하는 장르
/// - [_MyRatingsEntry] 내가 등록한 평점 화면으로 이동 (6주차)
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // 헤더 — 390 x 64, 제목 Manrope 700 / 22 / 28 #6750A4 (W8-06)
      appBar: AppHeader(
        title: '내 프로필',
        titleStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.primary,
        ),
        trailing: const _LogoutButton(),
      ),
      // 메인 컨텐츠 — padding 24 / 16, 섹션 사이 gap 32
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(),
            SizedBox(height: 32),
            _ProfileStats(),
            // W6-ENTRY — 통계 아래 26, 선호하는 장르 위 28
            SizedBox(height: 26),
            _MyRatingsEntry(),
            SizedBox(height: 28),
            _FavoriteGenres(),
          ],
        ),
      ),
    );
  }
}

/// Section - Profile Header Area — 프로필 사진, 닉네임·이메일, 프로필 수정 버튼
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        // border — 128 x 128, 테두리 2px, 이미지 124 x 124
        Container(
          width: 128,
          height: 128,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(color: AppColors.primary, width: 2),
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
                child: Icon(Icons.person, size: 64, color: colors.primary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _MemberSummary(),
        // 이메일 아래 ~ 프로필 수정 버튼 (W8-06)
        const SizedBox(height: 52),
        const _EditProfileButton(),
      ],
    );
  }
}

/// 닉네임 + 이메일 — `/members/me` 결과([AuthViewModel.member])를 그대로 보여줍니다.
///
/// 신규 로그인 직후에는 MainScreen의 loadMember가 끝날 때까지 로딩을,
/// 실패하면 로그아웃하지 않고 다시 시도 버튼을 보여줍니다.
class _MemberSummary extends StatelessWidget {
  const _MemberSummary();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final member = auth.member;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (member == null) {
      // 닉네임·이메일 두 줄과 같은 높이를 유지해 아래 버튼이 움직이지 않게 합니다.
      return SizedBox(
        height: 56,
        child: Center(
          child: auth.memberStatus == MemberLoadStatus.error
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '내 정보를 불러오지 못했어요.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: () => auth.loadMember(force: true),
                      child: const Text('다시 시도'),
                    ),
                  ],
                )
              : const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
        ),
      );
    }

    return Column(
      children: [
        // 닉네임 — Manrope 700 / 22 / 28
        Text(
          member.nickname,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.detailText,
          ),
        ),
        const SizedBox(height: 8),
        // 이메일 — Manrope 400 / 14 / 20
        Text(
          member.email,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// 헤더 오른쪽 로그아웃 — Manrope 700 / 14, #6750A4 (W8-06)
///
/// 화면 이동은 하지 않습니다. 세션이 signedOut이 되면 Router가 /login으로 보냅니다.
class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextButton(
      onPressed: () {
        // 7주차 학습용 memberId도 이전 계정의 값이 남지 않도록 함께 비웁니다.
        context.read<LearningMemberSession>().clear();
        context.read<AuthViewModel>().logout();
      },
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        // 글자 오른쪽 끝을 헤더 여백(16)에 맞춥니다. 누르는 영역은 왼쪽으로만 넓힙니다.
        padding: const EdgeInsets.only(left: 8),
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      child: const Text('로그아웃'),
    );
  }
}

/// 프로필 수정 버튼 — 127 x 42, radius 8, 테두리 1px #6750A4
/// 1주차 테마의 TextButton 스타일을 이 버튼에만 적용합니다.
/// 내 정보(member)가 있어야 수정할 값이 있으므로 그때만 켭니다.
class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasMember = context.select<AuthViewModel, bool>(
      (auth) => auth.member != null,
    );

    return TextButton(
      onPressed: hasMember ? () => context.push('/my/profile/edit') : null,
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        side: BorderSide(
          color: hasMember ? colors.primary : AppColors.primaryDisabled,
        ),
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        textStyle: Theme.of(context).textTheme.titleMedium,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('프로필 수정'),
    );
  }
}

/// Section - Statistics Bento Grid — 358 x 86, gap 8
class _ProfileStats extends StatelessWidget {
  const _ProfileStats();

  static const List<ProfileStat> stats = [
    ProfileStat(label: '본 영화', value: '342'),
    ProfileStat(label: '평점', value: '4.2'),
    ProfileStat(label: '즐겨찾기', value: '58'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        for (final stat in stats)
          Expanded(
            child: _StatItem(label: stat.label, value: stat.value),
          ),
      ],
    );
  }
}

/// 통계 항목 하나 — 114 x 86, padding 16, radius 12, 테두리 1px
class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

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
      // W8-06 — 라벨이 위, 숫자가 아래
      child: Column(
        children: [
          Text(label, textAlign: TextAlign.center, style: textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(value, textAlign: TextAlign.center, style: AppTheme.statValue),
        ],
      ),
    );
  }
}

/// 선호하는 장르 섹션 — 358 x 72, gap 16
class _FavoriteGenres extends StatelessWidget {
  const _FavoriteGenres();

  static const List<String> genres = ['드라마', 'SF', '애니메이션'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
          children: [
            for (final genre in genres)
              // 태그 칩 하나 — 66 x 32, padding 8 / 16, 배경 #E9DDFF, 글자 #4F378A
              TagChip(
                label: genre,
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                textStyle: textTheme.bodySmall,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// 내가 등록한 평점 진입 카드 — 358 x 64, 배경 #FFFFFF, 테두리 1.5px #D6C9E8 (W6-ENTRY)
/// 누르면 하단 탭 없이 /my/ratings 화면을 위에 띄웁니다.
class _MyRatingsEntry extends StatelessWidget {
  const _MyRatingsEntry();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: AppColors.entryCardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.statRadius),
        side: const BorderSide(color: AppColors.entryCardBorder, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/my/ratings'),
        child: SizedBox(
          height: 64,
          child: Padding(
            // 글자 왼쪽 19, 꺾쇠 오른쪽 18 (카드 바깥 기준)
            padding: const EdgeInsets.only(left: 19, right: 18),
            child: Row(
              children: [
                const Expanded(
                  child: Text('내가 등록한 평점', style: AppTheme.entryCardTitle),
                ),
                CustomPaint(
                  size: const Size(8, 14),
                  painter: _ChevronPainter(color: colors.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 오른쪽 꺾쇠 — 8 x 14, 선 2.5px, 끝은 둥글게
class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.color});

  final Color color;

  static const _strokeWidth = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    // 선 두께가 8 x 14 밖으로 나가지 않도록 절반만큼 안쪽에 그립니다.
    const inset = _strokeWidth / 2;
    final path = Path()
      ..moveTo(inset, inset)
      ..lineTo(size.width - inset, size.height / 2)
      ..lineTo(inset, size.height - inset);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter oldDelegate) => oldDelegate.color != color;
}
