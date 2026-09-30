import 'package:flutter/material.dart';

import 'data/movie.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('영화')),
      body: ListView.builder(
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return ListTile(
            leading: Image.asset(
              movie.posterAsset,
              width: 48,
              height: 72,
              fit: BoxFit.cover,
            ),
            title: Text(movie.title),
            subtitle: Text('${movie.genre} · ${movie.year}'),
          );
        },
      ),
    );
  }
}
