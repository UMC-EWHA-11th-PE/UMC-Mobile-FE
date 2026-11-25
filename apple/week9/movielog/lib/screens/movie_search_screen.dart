import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../view_models/paged_movies_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_states.dart';
import '../widgets/movie_page_footer.dart';
import '../widgets/movielog_button.dart';

/// W9 영화 검색 화면 — 탭 헤더의 검색 버튼으로 열고, 하단 NavigationBar 없이 표시합니다.
///
/// TMDB `/search/movie`를 [PagedMoviesViewModel]로 page 단위 조회합니다.
/// - 검색 결과: 영화 목록과 같은 그리드 + "검색 결과 더 보기"
/// - 빈 결과: "검색 결과가 없습니다."
/// - 오류: 안내 + 다시 시도
///
/// 검색어를 바꾸면 ViewModel이 generation을 올려, 이전 검색어의 늦은 응답을 버립니다.
class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key});

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    context.read<PagedMoviesViewModel>().search(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CommonAppBar(
        title: '영화 검색',
        titleStyle: AppTheme.appBarTitleBold,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 검색 입력 — 높이 46, radius 12, 오른쪽 "검색" (시안 추정값)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: '영화 제목을 입력하세요',
                fillColor: AppColors.entryCardBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                border: _border(AppColors.inputBorder),
                enabledBorder: _border(AppColors.inputBorder),
                focusedBorder: _border(colors.primary),
                suffixIcon: TextButton(
                  onPressed: _submit,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primary,
                    textStyle: AppTheme.movieLogButton,
                  ),
                  child: const Text('검색'),
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<PagedMoviesViewModel>(
              builder: (context, viewModel, _) => switch (viewModel.phase) {
                // 아직 검색하지 않음
                LoadPhase.idle => const SizedBox.shrink(),
                LoadPhase.loading => const MovieListLoading(),
                LoadPhase.empty => Center(
                  child: Text(
                    '검색 결과가 없습니다.',
                    style: AppTheme.entryCardTitle.copyWith(
                      fontSize: 17,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                LoadPhase.error => _SearchError(
                  message: viewModel.message ?? '검색 결과를 불러오지 못했습니다.',
                  onRetry: viewModel.retry,
                ),
                LoadPhase.ready => MovieGrid(
                  movies: viewModel.movies,
                  footer: MoviePageFooter(
                    hasMore: viewModel.hasMore,
                    isLoadingMore: viewModel.isLoadingMore,
                    failed: viewModel.loadMoreFailed,
                    onLoadMore: viewModel.loadMore,
                    loadMoreLabel: '검색 결과 더 보기',
                    failedMessage: '추가 검색 결과 조회에 실패했습니다.',
                    endMessage: '모든 검색 결과를 확인했습니다.',
                  ),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );
}

/// 검색 오류 — 안내 + 다시 시도 (W9 검색 오류)
class _SearchError extends StatelessWidget {
  const _SearchError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.entryCardTitle.copyWith(
              fontSize: 15,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          MovieLogButton(label: '다시 시도', width: 210, onPressed: onRetry),
        ],
      ),
    );
  }
}
