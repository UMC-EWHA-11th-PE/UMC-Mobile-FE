import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../view_models/movie_home_view_model.dart';
import '../widgets/tmdb_movie_card.dart';
import '../widgets/tmdb_poster_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        centerTitle: false,
        title: const Text(
          'MovieLog',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.violet,
          ),
        ),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: Consumer<MovieHomeViewModel>(
        builder: (context, viewModel, child) {
          return switch (viewModel.status) {
            MovieHomeLoadStatus.idle || MovieHomeLoadStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            MovieHomeLoadStatus.error => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(viewModel.message ?? '오류가 발생했어요.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<MovieHomeViewModel>().loadPopular(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
            MovieHomeLoadStatus.empty => const Center(
              child: Text('인기 영화가 없어요.'),
            ),
            MovieHomeLoadStatus.success => _HomeContent(
              movies: viewModel.popularMovies,
            ),
          };
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.movies});

  final List<TmdbMovieDto> movies;

  @override
  Widget build(BuildContext context) {
    final featured = movies.first;
    final date = featured.releaseDate;
    final year = (date != null && date.length >= 4)
        ? date.substring(0, 4)
        : null;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '오늘은 어떤\n영화를 볼까요?',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AspectRatio(
            aspectRatio: 0.75,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TmdbPosterImage(
                    posterPath: featured.posterPath,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.violet,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            '인기 1위',
                            style: TextStyle(color: AppColors.white),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          featured.title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          [
                            ?year,
                            '⭐ ${featured.voteAverage.toStringAsFixed(1)}',
                          ].join(' · '),
                          style: const TextStyle(color: AppColors.white),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                context.push('/movies/${featured.id}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.violet,
                              foregroundColor: AppColors.white,
                            ),
                            icon: const Icon(Icons.info),
                            label: const Text('상세보기'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '인기 영화',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => context.go('/movies'),
                child: const Text('전체보기 >'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: movies.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 130,
                child: TmdbMovieCard(movie: movies[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
