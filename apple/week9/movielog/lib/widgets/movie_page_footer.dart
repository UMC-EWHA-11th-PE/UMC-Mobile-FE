import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'movielog_button.dart';

/// 목록 아래 page 상태 — 더 보기 · 추가 로딩 · 다음 페이지 오류 · 마지막 페이지 (W9)
///
/// 상태는 ViewModel이 정해서 넘기고, Footer는 그대로 표시만 합니다.
/// - 다음 page가 있음: [loadMoreLabel] 버튼
/// - 불러오는 중([isLoadingMore]): 같은 자리의 회색 버튼 + 로딩 (MovieLogButton 통신 중 상태)
/// - 실패([failed]): 안내 문구 + "다음 페이지 다시 시도"
/// - 마지막 page: [endMessage]
class MoviePageFooter extends StatelessWidget {
  const MoviePageFooter({
    super.key,
    required this.hasMore,
    required this.isLoadingMore,
    required this.failed,
    required this.onLoadMore,
    this.loadMoreLabel = '더 보기',
    this.failedMessage = '추가 영화 조회에 실패했습니다.',
    this.endMessage = '모든 영화를 확인했습니다.',
  });

  final bool hasMore;
  final bool isLoadingMore;
  final bool failed;
  final VoidCallback onLoadMore;
  final String loadMoreLabel;
  final String failedMessage;
  final String endMessage;

  @override
  Widget build(BuildContext context) {
    final messageStyle = AppTheme.dialogBody.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (failed) ...[
            Text(
              failedMessage,
              textAlign: TextAlign.center,
              style: messageStyle,
            ),
            const SizedBox(height: 16),
            MovieLogButton(
              label: '다음 페이지 다시 시도',
              width: double.infinity,
              onPressed: onLoadMore,
            ),
          ] else if (hasMore || isLoadingMore)
            MovieLogButton(
              label: loadMoreLabel,
              width: double.infinity,
              isLoading: isLoadingMore,
              onPressed: onLoadMore,
            )
          else
            Text(endMessage, textAlign: TextAlign.center, style: messageStyle),
        ],
      ),
    );
  }
}
