import 'package:flutter/material.dart';

import 'data/fake_movie_service.dart';
import 'data/genre_preference.dart';
import 'data/movie.dart';
import 'theme/app_shadows.dart';
import 'widgets/app_header.dart';
import 'widgets/movie_grid.dart';
import 'widgets/movie_list_states.dart';

/// W3-02 영화 목록 화면입니다.
///
/// 4주차부터 영화 목록과 마지막으로 선택한 장르를 비동기로 불러오고,
/// [FutureBuilder]로 상태마다 다른 Widget을 보여줍니다.
/// - 불러오는 중: [MovieListLoading]
/// - 실패: [MovieListError] (다시 시도)
/// - 빈 목록: [MovieListEmpty]
/// - 성공: [_MovieListContent] 장르 필터 칩 + [MovieGrid]
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key, this.loadMode = MovieLoadMode.success});

  /// Mock 응답 시나리오 — 빈 목록·실패 화면을 확인할 때 바꿉니다.
  final MovieLoadMode loadMode;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

/// 화면에 처음 필요한 값 — 영화 목록과 마지막으로 선택한 장르
class MovieListInitialData {
  const MovieListInitialData({
    required this.movies,
    required this.selectedGenre,
  });

  final List<Movie> movies;
  final String selectedGenre;
}

class _MovieListScreenState extends State<MovieListScreen> {
  final _movieService = const FakeMovieService();
  final _genrePreference = GenrePreference();

  /// build가 다시 실행돼도 요청이 반복되지 않도록 initState·재시도에서만 만듭니다.
  late Future<MovieListInitialData> _initialDataFuture;

  @override
  void initState() {
    super.initState();
    _initialDataFuture = _loadInitialData();
  }

  /// 영화 목록과 저장된 장르는 서로 의존하지 않으므로 함께 시작합니다.
  Future<MovieListInitialData> _loadInitialData() async {
    final results = await Future.wait([
      _movieService.fetchMovies(mode: widget.loadMode),
      _genrePreference.read(),
    ]);

    return MovieListInitialData(
      movies: results[0] as List<Movie>,
      selectedGenre: results[1] as String,
    );
  }

  void _retry() {
    setState(() {
      _initialDataFuture = _loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader.tab(title: '영화'),
      body: FutureBuilder<MovieListInitialData>(
        future: _initialDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MovieListLoading();
          }

          if (snapshot.hasError) {
            return MovieListError(onRetry: _retry);
          }

          final data = snapshot.data;

          if (data == null || data.movies.isEmpty) {
            return const MovieListEmpty();
          }

          return _MovieListContent(
            movies: data.movies,
            initialGenre: data.selectedGenre,
            onGenreSelected: _genrePreference.save,
          );
        },
      ),
    );
  }
}

/// 성공 상태 — 장르 필터 칩과 영화 그리드
class _MovieListContent extends StatefulWidget {
  const _MovieListContent({
    required this.movies,
    required this.initialGenre,
    required this.onGenreSelected,
  });

  final List<Movie> movies;

  /// 마지막으로 선택했던 장르 — 지금 목록에 없는 장르면 전체로 시작합니다.
  final String initialGenre;
  final ValueChanged<String> onGenreSelected;

  @override
  State<_MovieListContent> createState() => _MovieListContentState();
}

class _MovieListContentState extends State<_MovieListContent> {
  static const _allGenres = GenrePreference.allGenres;

  /// 필터 칩 — 전체 + 영화 목록에 처음 등장한 순서대로의 장르
  late final List<String> _genres = [
    _allGenres,
    ...{for (final movie in widget.movies) movie.genre},
  ];

  late String _selectedGenre = _genres.contains(widget.initialGenre)
      ? widget.initialGenre
      : _allGenres;

  List<Movie> get _filteredMovies => _selectedGenre == _allGenres
      ? widget.movies
      : widget.movies.where((movie) => movie.genre == _selectedGenre).toList();

  void _selectGenre(String genre) {
    setState(() => _selectedGenre = genre);
    widget.onGenreSelected(genre);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMovies;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 필터 칩 영역 — 358 x 40, 헤더 아래 8, 그리드와 간격 16
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _GenreFilterBar(
            genres: _genres,
            selected: _selectedGenre,
            onSelected: _selectGenre,
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const MovieListEmpty()
              : MovieGrid(movies: filtered),
        ),
      ],
    );
  }
}

/// 필터 칩 영역 — 358 x 40, 가로 스크롤
/// 칩 높이는 32이고 아래 8은 그림자가 잘리지 않도록 남겨 둡니다.
class _GenreFilterBar extends StatelessWidget {
  const _GenreFilterBar({
    required this.genres,
    required this.selected,
    required this.onSelected,
  });

  final List<String> genres;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: genres.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) => _GenreChip(
          label: genres[index],
          selected: genres[index] == selected,
          onTap: () => onSelected(genres[index]),
        ),
      ),
    );
  }
}

/// 필터 칩 하나 — 높이 32, radius 9999, padding 8 / 16, box-shadow 0 1 2 #0000000D
/// 선택: 배경 #6750A4, 글자 #FFFFFF / 미선택: 배경 #E6E0E9, 글자 #494551
class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      selected: selected,
      button: true,
      child: DecoratedBox(
        decoration: const ShapeDecoration(
          shape: StadiumBorder(),
          shadows: AppShadows.card,
        ),
        child: Material(
          color: selected ? colors.primary : colors.surfaceContainerHighest,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              // Manrope 500 / 12 / 16, center
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: selected ? colors.onPrimary : colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
