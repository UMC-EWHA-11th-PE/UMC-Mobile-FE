import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/favorite_list_item.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_colors.dart';
import '../view_models/favorites_view_model.dart';
import '../view_models/load_phase.dart';
import '../widgets/movielog_button.dart';
import '../widgets/tmdb_movie_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key, required this.onOpenMovie});

  final Future<void> Function(TmdbMovieDto movie) onOpenMovie;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoritesViewModel>().refresh();
    });
  }

  Future<void> _open(FavoritesViewModel vm, TmdbMovieDto movie) async {
    await widget.onOpenMovie(movie);
    if (!mounted) return;
    await vm.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.warmWhite,
        title: const Text('내 즐겨찾기'),
        centerTitle: true,
      ),
      body: Consumer<FavoritesViewModel>(
        builder: (context, vm, _) {
          return switch (vm.phase) {
            LoadPhase.idle || LoadPhase.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            LoadPhase.empty => const Center(child: Text('아직 즐겨찾기한 영화가 없습니다.')),
            LoadPhase.error => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(vm.errorMessage ?? '조회 오류입니다.'),
                  const SizedBox(height: 12),
                  MovieLogButton(label: '다시 시도', onPressed: vm.refresh),
                ],
              ),
            ),
            LoadPhase.ready => RefreshIndicator(
              onRefresh: vm.refresh,
              child: GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.52,
                ),
                itemCount: vm.items.length,
                itemBuilder: (context, index) {
                  final item = vm.items[index];
                  final movie = item.movie;
                  if (movie == null) {
                    return _MissingMovieCard(item: item, vm: vm);
                  }
                  return TmdbMovieCard(
                    movie: movie,
                    onTap: () => _open(vm, movie),
                  );
                },
              ),
            ),
          };
        },
      ),
    );
  }
}

class _MissingMovieCard extends StatelessWidget {
  const _MissingMovieCard({required this.item, required this.vm});

  final FavoriteListItem item;
  final FavoritesViewModel vm;

  @override
  Widget build(BuildContext context) {
    final movieId = item.favorite.movieId;
    final isRetrying = vm.retrying.contains(movieId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.lavenderGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isRetrying
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : IconButton(
                      tooltip: '정보 재조회',
                      color: AppColors.violet,
                      icon: const Icon(Icons.refresh),
                      onPressed: () => vm.retryMovie(movieId),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '영화 #$movieId',
          maxLines: 1,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          item.errorMessage ?? '정보가 없습니다.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
