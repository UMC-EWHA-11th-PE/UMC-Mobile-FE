import 'package:flutter/material.dart';

import '../model/movie.dart';
import '../widget/movie_grid_card.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  String selectedGenre = '전체';

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
  Widget build(BuildContext context) {
    final filteredMovies = selectedGenre == '전체'
        ? movies
        : movies
            .where((movie) => movie.genre == selectedGenre)
            .toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Text(
              '영화',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 장르 목록
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
                    setState(() {
                      selectedGenre = genre;
                    });
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // 영화 목록
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              itemCount: filteredMovies.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
                childAspectRatio: 0.58,
              ),
              itemBuilder: (context, index) {
                final movie = filteredMovies[index];

                return MovieGridCard(
                  movie: movie,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}