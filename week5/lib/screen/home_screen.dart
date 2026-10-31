
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../model/movie.dart';
import '../widget/movie_card.dart';
import '../widget/tmdb_poster_image.dart';
import '../view_models/movie_home_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final featuredMovie = movies.first;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MovieLog',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              '오늘은 어떤\n영화를 볼까요?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 24),

            // 기존 추천 영화 유지
            MovieCard(movie: featuredMovie),

            const SizedBox(height: 32),

            const Text(
              '인기 영화',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // TMDB 인기 영화 5개
            Consumer<MovieHomeViewModel>(
              builder: (context, vm, child) {
                switch (vm.status) {
                  case MovieHomeLoadStatus.idle:
                  case MovieHomeLoadStatus.loading:
                    return const SizedBox(
                      height: 250,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                  case MovieHomeLoadStatus.error:
                    return Column(
                      children: [
                        Text(
                          vm.message ?? '오류가 발생했습니다.',
                        ),
                        ElevatedButton(
                          onPressed: () {
                            context
                                .read<MovieHomeViewModel>()
                                .loadPopular();
                          },
                          child: const Text('다시 시도'),
                        ),
                      ],
                    );

                  case MovieHomeLoadStatus.empty:
                    return const Text(
                      '인기 영화가 없습니다.',
                    );

                  case MovieHomeLoadStatus.success:
                    return SizedBox(
                      height: 250,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: vm.popularMovies.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final movie =
                              vm.popularMovies[index];

                          return GestureDetector(
                            onTap: () {
                              context.push(
                                '/movies/${movie.id}',
                              );
                            },
                            child: SizedBox(
                              width: 140,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      child: TmdbPosterImage(
                                        posterPath: movie.posterPath,
                                        width: 140,
                                        height: 200,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  Text(
                                    movie.title,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    '⭐ ${movie.voteAverage.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                }
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}