import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// W3-01 영화 홈 화면입니다.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _HomeHeader(),
      body: Center(child: Text('홈 화면')),
    );
  }
}

/// 헤더 — 388 x 64, padding 0 / 16, 배경 #FAF9F5, space-between
/// 왼쪽 MovieLog 로고, 오른쪽 검색 버튼
class _HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  const _HomeHeader();

  static const double _height = 64;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: colors.surface,
      // 상태 표시줄 영역까지 배경을 칠하고 내용은 그 아래에 배치
      child: SafeArea(
        bottom: false,
        child: Container(
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 헤딩 — Manrope 700 / 22 / 28 / -0.55, #4F378A
              Text(
                'MovieLog',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.55,
                  color: colors.onPrimaryContainer,
                ),
              ),
              // 우측 버튼 — 34 x 34, radius 9999, padding 8, 아이콘 18 x 18
              IconButton(
                onPressed: () {}, // 검색 화면은 아직 연결하지 않습니다.
                icon: SvgPicture.asset(
                  'assets/icons/header_search.svg',
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    colors.onPrimaryContainer,
                    BlendMode.srcIn,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                style: IconButton.styleFrom(
                  shape: const CircleBorder(),
                  // 기본 48x48 터치 영역 여백을 없애 Figma 34x34에 맞춤
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                tooltip: '검색',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
