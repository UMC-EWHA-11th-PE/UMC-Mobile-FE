import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../view_models/paged_movies_view_model.dart';
import 'movielog_button.dart';

/// 목록 아래 page 상태 — [PagedMoviesViewModel]의 상태를 그대로 그립니다. (W9)
///
/// - 다음 page가 있음: [loadMoreLabel] 버튼
/// - 불러오는 중([PagedMoviesViewModel.isLoadingMore]): 버튼 비활성 + 로딩 (MovieLogButton 통신 중 상태)
/// - 실패([PagedMoviesViewModel.loadMoreError]): 안내 문구 + "다음 페이지 다시 시도" (같은 page)
/// - 마지막 page: [endMessage] (TMDB 최대 500 page의 끝 포함)
class MoviePageFooter extends StatelessWidget {
  const MoviePageFooter({
    super.key,
    required this.vm,
    this.loadMoreLabel = '더 보기',
    this.endMessage = '모든 영화를 확인했습니다.',
  });

  final PagedMoviesViewModel vm;
  final String loadMoreLabel;
  final String endMessage;

  @override
  Widget build(BuildContext context) {
    final messageStyle = AppTheme.dialogBody.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final error = vm.loadMoreError;

    if (!vm.hasMore && !vm.isLoadingMore && error == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Text(
          endMessage,
          textAlign: TextAlign.center,
          style: messageStyle,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (error != null) ...[
            Text(error, textAlign: TextAlign.center, style: messageStyle),
            const SizedBox(height: 16),
          ],
          MovieLogButton(
            width: double.infinity,
            label: error == null ? loadMoreLabel : '다음 페이지 다시 시도',
            isLoading: vm.isLoadingMore,
            onPressed: vm.phase == LoadPhase.ready ? vm.loadNextPage : null,
          ),
        ],
      ),
    );
  }
}
