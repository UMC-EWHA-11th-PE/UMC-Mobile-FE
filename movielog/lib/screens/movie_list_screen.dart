import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../theme/app_colors.dart';
import '../view_models/load_phase.dart';
import '../view_models/paged_movies_view_model.dart';
import '../widgets/movie_list_status.dart';
import '../widgets/movie_page_footer.dart';
import '../widgets/tmdb_movie_card.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  List<TmdbGenreDto> _genres = const [];

  @override
  void initState() {
    super.initState();
    _loadGenres();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PagedMoviesViewModel>().loadInitial();
    });
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await context.read<TmdbMovieService>().fetchGenres();
      if (mounted) setState(() => _genres = genres);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        centerTitle: false,
        title: const Text(
          '영화',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.violet,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/movies/search'),
          ),
        ],
      ),
      body: Consumer<PagedMoviesViewModel>(
        builder: (context, vm, child) {
          return Column(
            children: [
              _GenreChips(genres: _genres, vm: vm),
              Expanded(
                child: switch (vm.phase) {
                  LoadPhase.idle ||
                  LoadPhase.loading => const MovieListLoading(),
                  LoadPhase.error => MovieListError(
                    onRetry: () => vm.loadInitial(genreId: vm.genreId),
                    onCancel: () => context.go('/home'),
                  ),
                  LoadPhase.empty => const MovieListEmpty(),
                  LoadPhase.ready => CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        sliver: SliverGrid.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.52,
                              ),
                          itemCount: vm.movies.length,
                          itemBuilder: (context, index) =>
                              TmdbMovieCard(movie: vm.movies[index]),
                        ),
                      ),
                      SliverToBoxAdapter(child: MoviePageFooter(vm: vm)),
                    ],
                  ),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GenreChips extends StatelessWidget {
  const _GenreChips({required this.genres, required this.vm});

  final List<TmdbGenreDto> genres;
  final PagedMoviesViewModel vm;

  @override
  Widget build(BuildContext context) {
    final items = <(int?, String)>[
      (null, '전체'),
      ...genres.map((genre) => (genre.id, genre.name)),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (genreId, name) = items[index];
          final isSelected = genreId == vm.genreId;

          return ChoiceChip(
            label: Text(name),
            selected: isSelected,
            showCheckmark: false,
            shape: const StadiumBorder(),
            side: BorderSide.none,
            selectedColor: AppColors.violet,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.white : AppColors.black,
            ),
            onSelected: (_) => vm.loadInitial(genreId: genreId),
          );
        },
      ),
    );
  }
}
