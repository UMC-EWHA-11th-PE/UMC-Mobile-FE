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
/// - 오류: 안내 + 다시 시도 (마지막으로 제출한 검색어로)
/// - 처음 진입(idle)과 결과 없음(empty)을 구분합니다.
///
/// 글자를 입력할 때마다 요청하지 않고 제출할 때만, 새 검색은 page 1부터 요청합니다.
/// 빈 검색어는 서버에 보내지 않고 입력 안내를 보여 줍니다.
/// 검색어를 바꾸면 ViewModel이 generation을 올려, 이전 검색어의 늦은 응답을 버립니다.
class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key});

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final _controller = TextEditingController();

  /// 마지막으로 제출한 검색어 — 오류 화면의 다시 시도에 씁니다.
  String _submittedQuery = '';

  /// 빈 검색어를 제출했을 때 입력칸 아래 안내
  String? _inputError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() => _inputError = '검색어를 입력합니다.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _inputError = null;
      _submittedQuery = query;
    });
    context.read<PagedMoviesViewModel>().loadInitial(query: query);
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
                errorText: _inputError,
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
                // 아직 검색하지 않음 — 결과 없음(empty)과 구분합니다.
                LoadPhase.idle => Center(
                  child: Text(
                    '검색어를 입력합니다.',
                    style: AppTheme.dialogBody.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
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
                  message: viewModel.errorMessage ?? '검색 결과를 불러오지 못했습니다.',
                  onRetry: () => viewModel.loadInitial(query: _submittedQuery),
                ),
                LoadPhase.ready => MovieGrid(
                  movies: viewModel.movies,
                  footer: MoviePageFooter(
                    vm: viewModel,
                    loadMoreLabel: '검색 결과 더 보기',
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
