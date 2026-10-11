import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/genre_preference.dart';
import '../data/mock_movies.dart';
import '../services/fake_movie_service.dart';
import '../theme/app_colors.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_status.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  static const genres = ['전체', '드라마', 'SF', '애니메이션', '스릴러', '로맨스', '다큐멘터리'];

  final movieService = const FakeMovieService();
  final genrePreference = GenrePreference();

  // 화면 상태 확인용: success, empty, failure
  final loadMode = MovieLoadMode.success;

  late Future<List<Movie>> _moviesFuture;
  String selectedGenre = '전체';

  @override
  void initState() {
    super.initState();
    _moviesFuture = movieService.fetchMovies(mode: loadMode);
    _loadSelectedGenre();
  }

  Future<void> _loadSelectedGenre() async {
    final genre = await genrePreference.read();

    if (!mounted) return;

    setState(() {
      selectedGenre = genre;
    });
  }

  void _retry() {
    setState(() {
      _moviesFuture = movieService.fetchMovies();
    });
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
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: genres.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final genre = genres[index];
                final isSelected = genre == selectedGenre;

                return ChoiceChip(
                  label: Text(genre),
                  selected: isSelected,
                  showCheckmark: false,
                  shape: const StadiumBorder(),
                  side: BorderSide.none,
                  selectedColor: AppColors.violet,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.black,
                  ),
                  onSelected: (_) async {
                    setState(() {
                      selectedGenre = genre;
                    });
                    await genrePreference.save(genre);
                  },
                );
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Movie>>(
              future: _moviesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const MovieListLoading();
                }

                if (snapshot.hasError) {
                  return MovieListError(
                    onRetry: _retry,
                    onCancel: () => context.go('/home'),
                  );
                }

                final loadedMovies = snapshot.data ?? const <Movie>[];
                final filteredMovies = selectedGenre == '전체'
                    ? loadedMovies
                    : loadedMovies
                          .where((movie) => movie.genre == selectedGenre)
                          .toList();

                if (filteredMovies.isEmpty) {
                  return const MovieListEmpty();
                }

                return MovieGrid(movies: filteredMovies);
              },
            ),
          ),
        ],
      ),
    );
  }
}
