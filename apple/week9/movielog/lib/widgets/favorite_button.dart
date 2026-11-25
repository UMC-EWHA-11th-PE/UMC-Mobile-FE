import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/favorite_detail_view_model.dart';

/// 영화 상세 제목·정보 텍스트 오른쪽의 즐겨찾기(북마크) 버튼 (W9)
///
/// [FavoriteDetailViewModel]을 구독해 그립니다.
/// - 등록 전: 빈 북마크 / 등록 후: 채워진 북마크
/// - 첫 여부 조회·등록·해제 중: 북마크 자리에만 로딩, 누를 수 없음
/// - 실패: 이전 아이콘 유지 + Snackbar (상세 하단에도 안내)
/// - 첫 여부 조회 실패: 아래에 "여부 다시 확인" 새로고침 버튼
///
/// 결과는 3주차처럼 Snackbar로 안내하되, 문구는 서버 요청 결과를 따릅니다.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key});

  Future<void> _toggle(BuildContext context, FavoriteDetailViewModel vm) async {
    final changedTo = await vm.toggle();
    if (!context.mounted) return;
    final message = changedTo != null
        ? (changedTo ? '즐겨찾기에 추가했습니다.' : '즐겨찾기를 해제했습니다.')
        : vm.errorMessage;
    if (message == null) return; // 세션 만료 등 — 로그인 화면이 안내합니다.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteDetailViewModel>(
      builder: (context, vm, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FavoriteBookmarkBox(
              isFavorite: vm.isFavorite,
              isLoading: vm.isLoading || vm.isSaving,
              onPressed: vm.hasLoadedStatus ? () => _toggle(context, vm) : null,
            ),
            // 첫 여부 조회에 실패했을 때만 북마크와 같은 너비의 새로고침 버튼을 보여 줍니다.
            if (!vm.hasLoadedStatus && !vm.isLoading)
              SizedBox(
                width: FavoriteBookmarkBox.size.width,
                child: IconButton(
                  tooltip: '여부 다시 확인',
                  color: AppColors.primary,
                  onPressed: vm.load,
                  icon: const Icon(Icons.refresh),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 북마크 박스 + "즐겨찾기" 라벨 — 표시만 합니다. (Mock 영화 상세에서도 재사용)
///
/// 박스 62 x 64, radius 12, 테두리 1px #D9D3E1, 배경 #FFFFFF, 아이콘 18 x 24 #6750A4
/// 라벨 Manrope 700 / 10, #6750A4, 박스 아래 8 — 수치가 없어 W9 시안에서 추정
class FavoriteBookmarkBox extends StatelessWidget {
  const FavoriteBookmarkBox({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.isLoading = false,
  });

  static const size = Size(62, 64);

  final bool isFavorite;
  final bool isLoading;

  /// null이면 누를 수 없음 (여부 확인 전·요청 중)
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primary;

    final Widget icon;
    if (isLoading) {
      icon = const SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
    } else if (isFavorite) {
      // 즐겨찾기 상태는 제공된 북마크 아이콘(W3-REQ)을 사용합니다.
      icon = Image.asset(
        'assets/icons/bookmark_filled.png',
        width: 18,
        height: 24,
        fit: BoxFit.contain,
        color: color,
        colorBlendMode: BlendMode.srcIn,
      );
    } else {
      icon = SvgPicture.asset(
        'assets/icons/detail_bookmark.svg',
        width: 18,
        height: 24,
        colorFilter: const ColorFilter.mode(color, BlendMode.srcIn),
      );
    }

    return Semantics(
      button: true,
      toggled: isFavorite,
      enabled: onPressed != null && !isLoading,
      label: '즐겨찾기',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.fromSize(
            size: size,
            child: Material(
              color: AppColors.entryCardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.inputBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: isLoading ? null : onPressed,
                child: Center(child: icon),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '즐겨찾기',
            style: TextStyle(
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
