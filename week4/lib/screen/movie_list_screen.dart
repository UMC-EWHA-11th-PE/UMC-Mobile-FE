import 'package:flutter/material.dart';

import '../model/movie.dart';
import '../service/fake_movie_service.dart';
import '../storage/genre_preference.dart';
import '../widget/movie_grid.dart';
import '../widget/movie_list_loading.dart';
import '../widget/movie_list_empty.dart';
import '../widget/movie_list_error.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  String selectedGenre = '전체';
  MovieLoadMode _loadMode = MovieLoadMode.failure;

  final FakeMovieService movieService = const FakeMovieService();

  final GenrePreference genrePreference = GenrePreference();

  late Future<List<Movie>> _moviesFuture;

  final List<String> genres = [
    '전체',
    '드라마',
    'SF',
    '애니메이션',
    '스릴러',
    '로맨스',
    '다큐멘터리',
  ];

  @override
  void initState() {
    super.initState();

    _moviesFuture = movieService.fetchMovies(mode: _loadMode);
  }

  void _retry() {
    setState(() {
      // 실패 상태에서 재시도하면 성공 모드로 변경
      if (_loadMode == MovieLoadMode.failure) {
        _loadMode = MovieLoadMode.success;
      }

      _moviesFuture = movieService.fetchMovies(mode: _loadMode);
    });
  }

  Future<void> _selectGenre(String genre) async {
    setState(() {
      selectedGenre = genre;
    });

    try {
      await genrePreference.save(genre);
    } catch (error) {
      debugPrint('장르 저장 실패: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 영화 목록 제목
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Text(
              '영화',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),

          // 장르 선택 Chip
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: genres.length,
              separatorBuilder: (context, index) {
                return const SizedBox(width: 8);
              },
              itemBuilder: (context, index) {
                final genre = genres[index];

                return ChoiceChip(
                  label: Text(genre),
                  selected: selectedGenre == genre,
                  onSelected: (selected) {
                    if (selected) {
                      _selectGenre(genre);
                    }
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // 비동기 영화 목록
          Expanded(
            child: FutureBuilder<List<Movie>>(
              future: _moviesFuture,
              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState != ConnectionState.done) {
                  return const MovieListLoading();
                }

                // Error
                if (snapshot.hasError) {
                  return MovieListError(onRetry: _retry);
                }

                // 데이터 가져오기
                final loadedMovies = snapshot.data ?? <Movie>[];

                // 장르 필터링
                final filteredMovies = selectedGenre == '전체'
                    ? loadedMovies
                    : loadedMovies
                          .where((movie) => movie.genre == selectedGenre)
                          .toList();

                // Empty
                if (filteredMovies.isEmpty) {
                  return const MovieListEmpty();
                }

                // Success
                return MovieGrid(movies: filteredMovies);
              },
            ),
          ),
        ],
      ),
    );
  }
}
