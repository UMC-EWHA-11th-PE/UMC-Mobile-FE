import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import '../widgets/movie_page_footer.dart';
import '../widgets/movielog_button.dart';
import '../widgets/tmdb_poster_image.dart';

class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key, required this.onOpenMovie});

  final Future<void> Function(TmdbMovieDto movie) onOpenMovie;

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final text = TextEditingController();
  String submittedQuery = '';
  String? inputError;

  void submitSearch(String value) {
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => inputError = '검색어를 입력해 주세요.');
      return;
    }
    setState(() {
      inputError = null;
      submittedQuery = query;
    });
    context.read<PagedMoviesViewModel>().loadInitial(query: query);
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        title: const Text('영화 검색'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: text,
                    textInputAction: TextInputAction.search,
                    onSubmitted: submitSearch,
                    decoration: InputDecoration(
                      labelText: '검색어',
                      errorText: inputError,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => submitSearch(text.text),
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<PagedMoviesViewModel>(
              builder: (context, vm, _) {
                return switch (vm.phase) {
                  LoadPhase.idle => const Center(child: Text('검색어를 입력해 주세요.')),
                  LoadPhase.loading => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  LoadPhase.error => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(vm.errorMessage ?? '조회 오류입니다.'),
                        const SizedBox(height: 12),
                        MovieLogButton(
                          label: '다시 시도',
                          onPressed: () =>
                              vm.loadInitial(query: submittedQuery),
                        ),
                      ],
                    ),
                  ),
                  LoadPhase.empty => const Center(child: Text('검색 결과가 없습니다.')),
                  LoadPhase.ready => ListView.builder(
                    itemCount: vm.movies.length + 1,
                    itemBuilder: (context, index) {
                      if (index == vm.movies.length) {
                        return MoviePageFooter(vm: vm);
                      }
                      final movie = vm.movies[index];
                      final date = movie.releaseDate;
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TmdbPosterImage(
                            posterPath: movie.posterPath,
                            width: 40,
                            height: 60,
                          ),
                        ),
                        title: Text(movie.title),
                        subtitle: date != null && date.length >= 4
                            ? Text(date.substring(0, 4))
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => widget.onOpenMovie(movie),
                      );
                    },
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}
