
import 'package:flutter/foundation.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/models/tmdb_genre_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus {
  idle,
  loading,
  success,
  empty,
  error,
}

class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service);

  final TmdbMovieService _service;

  List<TmdbMovieDto> movies = [];
  List<TmdbGenreDto> genres = [];

  int? selectedGenreId;
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;

  int _requestVersion = 0;
  bool _disposed = false;

  bool get isLoading =>
      status == MovieListLoadStatus.loading;

  Future<List<TmdbMovieDto>> fetchUpToThirtyMovies({
    int? genreId,
  }) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < 30 && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreId: genreId,
      );

      for (final movie in page.results) {
        byId[movie.id] = movie;
        if (byId.length == 30) break;
      }

      hasNextPage =
          pageNumber < page.totalPages &&
          page.results.isNotEmpty;

      pageNumber++;
    }

    return byId.values.take(30).toList();
  }

  Future<void> loadInitial() async {
    if (isLoading) return;

    final version = ++_requestVersion;
    status = MovieListLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      genres = await _service.fetchGenres();
      final result = await fetchUpToThirtyMovies();

      if (_disposed || version != _requestVersion) return;

      movies = result;
      selectedGenreId = null;
      status = movies.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } catch (error) {
      if (_disposed || version != _requestVersion) return;

      status = MovieListLoadStatus.error;
      message = '영화를 불러오지 못했어요.';
      debugPrint('TMDB 목록 오류: $error');
    }

    if (!_disposed && version == _requestVersion) {
      notifyListeners();
    }
  }

  Future<void> selectGenre(int? genreId) async {
    if (isLoading) return;

    selectedGenreId = genreId;
    final version = ++_requestVersion;

    status = MovieListLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final result = await fetchUpToThirtyMovies(
        genreId: genreId,
      );

      if (_disposed || version != _requestVersion) return;

      movies = result;
      status = result.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } catch (error) {
      if (_disposed || version != _requestVersion) return;

      status = MovieListLoadStatus.error;
      message = '해당 장르 영화를 불러오지 못했어요.';
      debugPrint('TMDB 장르 오류: $error');
    }

    if (!_disposed && version == _requestVersion) {
      notifyListeners();
    }
  }

  Future<void> retry() async {
    if (isLoading) return;

    if (genres.isEmpty) {
      await loadInitial();
    } else {
      await selectGenre(selectedGenreId);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
