import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import 'movie_detail_screen.dart';

/// 영화 상세의 시작점입니다. (7주차)
/// 목록에서 넘긴 extra가 있으면 그대로 쓰고, 없으면(직접 접근·딥링크)
/// TMDB GET /movie/{id}로 다시 조회합니다.
class MovieDetailLoader extends StatefulWidget {
  const MovieDetailLoader({
    super.key,
    required this.movieId,
    this.initialMovie,
  });

  final int movieId;
  final TmdbMovieDto? initialMovie;

  @override
  State<MovieDetailLoader> createState() => _MovieDetailLoaderState();
}

class _MovieDetailLoaderState extends State<MovieDetailLoader> {
  late Future<TmdbMovieDto> _movieFuture;

  @override
  void initState() {
    super.initState();
    _movieFuture = _load();
  }

  Future<TmdbMovieDto> _load() {
    final initial = widget.initialMovie;
    if (initial != null) return Future.value(initial);
    return context.read<TmdbMovieService>().fetchMovieDetail(widget.movieId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TmdbMovieDto>(
      future: _movieFuture, // build마다 새 Future를 만들지 않습니다.
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final movie = snapshot.data;
        if (snapshot.hasError || movie == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('영화를 불러오지 못했습니다.'),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _movieFuture = _load()),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          );
        }
        return MovieDetailScreen(movie: movie);
      },
    );
  }
}
