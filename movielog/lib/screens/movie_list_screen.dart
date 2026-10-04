import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../theme/app_colors.dart';
import '../widgets/movie_card.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  String selectedGenre = '전체';

  @override
  Widget build(BuildContext context) {
    final genres = ['전체', ...movies.map((movie) => movie.genre).toSet()];
    final filteredMovies = selectedGenre == '전체'
        ? movies
        : movies.where((movie) => movie.genre == selectedGenre).toList();

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
                  shape: StadiumBorder(),
                  side: BorderSide.none,
                  selectedColor: AppColors.violet,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.white : AppColors.black,
                  ),
                  onSelected: (_) {
                    setState(() {
                      selectedGenre = genre;
                    });
                  },
                );
              },
            ),
          ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredMovies.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.55,
              ),
              itemBuilder: (context, index) {
                return MovieCard(movie: filteredMovies[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
