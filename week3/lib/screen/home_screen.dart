import 'package:flutter/material.dart';

import '../model/movie.dart';
import '../widget/movie_card.dart';
import '../widget/home_movie_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final featuredMovie = movies.first;
    final popularMovies = movies.skip(1).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MovieLog',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              '오늘은 어떤\n영화를 볼까요?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 24),

            // 메인 추천 영화
            MovieCard(
              movie: featuredMovie,
            ),

            const SizedBox(height: 32),

            // 인기 영화 제목
            const Text(
              '인기 영화',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // 나머지 영화 가로 목록
            SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: popularMovies.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(width: 12);
                },
                itemBuilder: (context, index) {
                  return HomeMovieCard(
                    movie: popularMovies[index],
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}