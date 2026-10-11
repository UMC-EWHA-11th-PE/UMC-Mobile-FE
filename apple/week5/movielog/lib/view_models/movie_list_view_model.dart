import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/local/genre_preference.dart';
import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';

enum MovieListLoadStatus { idle, loading, success, empty, error }

/// 영화 목록 화면의 상태 — Discover 최대 30개, 장르 목록, 선택한 장르
class MovieListViewModel extends ChangeNotifier {
  MovieListViewModel(this._service, {GenrePreference? genrePreference})
    : _genrePreference = genrePreference ?? GenrePreference();

  final TmdbMovieService _service;

  /// 마지막으로 선택한 장르 id를 저장해 다음 진입 때 그 장르로 시작합니다. (4주차)
  final GenrePreference _genrePreference;

  /// 목록에 보여줄 최대 개수 (화면 정책)
  static const maxMovies = 30;

  List<TmdbMovieDto> movies = const [];
  List<TmdbGenreDto> genres = const [];

  /// null이면 "전체" — with_genres 없이 조회합니다.
  int? selectedGenreId;
  MovieListLoadStatus status = MovieListLoadStatus.idle;
  String? message;

  /// Discover 요청 중에는 장르를 바꿀 수 없습니다.
  bool get isLoading =>
      status == MovieListLoadStatus.idle ||
      status == MovieListLoadStatus.loading;

  /// 장르 id → 이름 (영화 카드 소제목용)
  Map<int, String> get genreNames => {
    for (final genre in genres) genre.id: genre.name,
  };

  /// 요청마다 1씩 올려, 늦게 도착한 이전 요청의 결과를 무시합니다.
  int _requestVersion = 0;
  bool _disposed = false;

  /// Discover를 page 1부터 요청해 중복 없는 영화를 최대 30개 모읍니다.
  ///
  /// 한 페이지 개수를 가정하지 않고, 30개가 되거나 마지막 페이지가 될 때까지 요청합니다.
  /// TMDB id를 Map key로 써서 페이지 사이에 중복된 영화는 하나만 남깁니다.
  /// 30개보다 적으면 있는 만큼만 돌려주며 오류로 보지 않습니다.
  Future<List<TmdbMovieDto>> fetchUpToThirtyMovies({int? genreId}) async {
    final byId = <int, TmdbMovieDto>{};
    var pageNumber = 1;
    var hasNextPage = true;

    while (byId.length < maxMovies && hasNextPage) {
      final page = await _service.discoverMovies(
        page: pageNumber,
        genreId: genreId,
      );

      for (final movie in page.results) {
        byId[movie.id] = movie;
        if (byId.length == maxMovies) break;
      }

      hasNextPage = pageNumber < page.totalPages && page.results.isNotEmpty;
      pageNumber++;
    }

    return byId.values.take(maxMovies).toList();
  }

  /// 처음 진입·다시 시도 — 장르 목록과 마지막으로 선택한 장르의 영화 30개를 불러옵니다.
  Future<void> loadInitial() async {
    final version = ++_requestVersion;
    status = MovieListLoadStatus.loading;
    notifyListeners();

    try {
      genres = await _service.fetchGenres();
      final savedGenreId = await _genrePreference.read();
      // 저장된 장르가 지금 장르 목록에 없으면 전체로 시작합니다.
      selectedGenreId = genres.any((genre) => genre.id == savedGenreId)
          ? savedGenreId
          : null;
      final discovered = await fetchUpToThirtyMovies(genreId: selectedGenreId);

      if (_disposed || version != _requestVersion) return;
      movies = discovered;
      status = movies.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } on DioException {
      if (_disposed || version != _requestVersion) return;
      status = MovieListLoadStatus.error;
      message = '영화를 불러오지 못했어요. 다시 시도해 주세요.';
    }

    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  /// 장르 선택 — with_genres로 page 1부터 다시 조회합니다. null이면 전체입니다.
  Future<void> selectGenre(int? genreId) async {
    if (isLoading) return;
    selectedGenreId = genreId;
    unawaited(_genrePreference.save(genreId));
    final version = ++_requestVersion;
    status = MovieListLoadStatus.loading;
    notifyListeners();

    try {
      final result = await fetchUpToThirtyMovies(genreId: genreId);
      if (_disposed || version != _requestVersion) return;
      movies = result;
      status = result.isEmpty
          ? MovieListLoadStatus.empty
          : MovieListLoadStatus.success;
    } on DioException {
      if (_disposed || version != _requestVersion) return;
      status = MovieListLoadStatus.error;
      message = '해당 장르 영화를 불러오지 못했어요.';
    }

    if (!_disposed && version == _requestVersion) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    super.dispose();
  }
}
