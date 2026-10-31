
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../view_models/movie_list_view_model.dart';
import '../widget/tmdb_poster_image.dart';
import '../widget/movie_list_loading.dart';
import '../widget/movie_list_empty.dart';
import '../widget/movie_list_error.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Text(
              '영화',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Consumer<MovieListViewModel>(
            builder: (context, vm, child) {
              return SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('전체'),
                        selected: vm.selectedGenreId == null,
                        onSelected: vm.isLoading
                            ? null
                            : (_) => vm.selectGenre(null),
                      ),
                    ),
                    ...vm.genres.map((genre) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(genre.name),
                          selected:
                              vm.selectedGenreId == genre.id,
                          onSelected: vm.isLoading
                              ? null
                              : (_) => vm.selectGenre(genre.id),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          Expanded(
            child: Consumer<MovieListViewModel>(
              builder: (context, vm, child) {
                switch (vm.status) {
                  case MovieListLoadStatus.idle:
                  case MovieListLoadStatus.loading:
                    return const MovieListLoading();

                  case MovieListLoadStatus.error:
                    return MovieListError(
                      onRetry: () {
                        context
                            .read<MovieListViewModel>()
                            .retry();
                      },
                    );

                  case MovieListLoadStatus.empty:
                    return const MovieListEmpty();

                  case MovieListLoadStatus.success:
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: vm.movies.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.58,
                      ),
                      itemBuilder: (context, index) {
                        final movie = vm.movies[index];

                        return GestureDetector(
                          onTap: () {
                            context.push('/movies/${movie.id}');
                          },
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return TmdbPosterImage(
                                        posterPath: movie.posterPath,
                                        width: constraints.maxWidth,
                                        height: constraints.maxHeight,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                movie.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                movie.releaseDate
                                        ?.split('-')
                                        .first ??
                                    '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}