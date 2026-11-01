import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/movie_list_view_model.dart';
import '../widgets/movie_list_status.dart';
import '../widgets/tmdb_movie_grid.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

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
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: Consumer<MovieListViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              _GenreChips(viewModel: viewModel),
              Expanded(
                child: switch (viewModel.status) {
                  MovieListLoadStatus.idle ||
                  MovieListLoadStatus.loading => const MovieListLoading(),
                  MovieListLoadStatus.error => MovieListError(
                    onRetry: () => context.read<MovieListViewModel>().retry(),
                    onCancel: () => context.go('/home'),
                  ),
                  MovieListLoadStatus.empty => const MovieListEmpty(),
                  MovieListLoadStatus.success => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text('총 ${viewModel.movies.length}편'),
                      ),
                      Expanded(child: TmdbMovieGrid(movies: viewModel.movies)),
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
  const _GenreChips({required this.viewModel});

  final MovieListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final items = <(int?, String)>[
      (null, '전체'),
      ...viewModel.genres.map((genre) => (genre.id, genre.name)),
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
          final isSelected = genreId == viewModel.selectedGenreId;

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
            onSelected: viewModel.isLoading
                ? null
                : (_) =>
                      context.read<MovieListViewModel>().selectGenre(genreId),
          );
        },
      ),
    );
  }
}
