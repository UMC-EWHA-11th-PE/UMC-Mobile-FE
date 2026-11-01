import 'package:flutter/material.dart';

import '../data/models/tmdb_movie_dto.dart';
import 'tmdb_movie_card.dart';

class TmdbMovieGrid extends StatelessWidget {
  const TmdbMovieGrid({super.key, required this.movies});

  final List<TmdbMovieDto> movies;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.52,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) => TmdbMovieCard(movie: movies[index]),
    );
  }
}
