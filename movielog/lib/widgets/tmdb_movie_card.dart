import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/tmdb_movie_dto.dart';
import 'tmdb_poster_image.dart';

class TmdbMovieCard extends StatelessWidget {
  const TmdbMovieCard({super.key, required this.movie, this.onTap});

  final TmdbMovieDto movie;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final date = movie.releaseDate;
    final year = (date != null && date.length >= 4)
        ? date.substring(0, 4)
        : null;

    return InkWell(
      onTap: onTap ?? () => context.push('/movies/${movie.id}', extra: movie),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: TmdbPosterImage(
                posterPath: movie.posterPath,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            [?year, '⭐ ${movie.voteAverage.toStringAsFixed(1)}'].join(' · '),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
