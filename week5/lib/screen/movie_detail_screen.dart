
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../widget/movie_rating_input.dart';
import '../widget/tmdb_poster_image.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({
    super.key,
    required this.movieId,
  });

  final String movieId;

  @override
  State<MovieDetailScreen> createState() =>
      _MovieDetailScreenState();
}

class _MovieDetailScreenState
    extends State<MovieDetailScreen> {
  late Future<TmdbMovieDto> _movieFuture;

  double selectedRating = 0;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();

    final movieId = int.tryParse(widget.movieId);

    if (movieId == null) {
      _movieFuture = Future.error(
        const FormatException('잘못된 영화 ID'),
      );
    } else {
      _movieFuture = context
          .read<TmdbMovieService>()
          .fetchMovieDetail(movieId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cinema Archive'),
      ),

      body: FutureBuilder<TmdbMovieDto>(
        future: _movieFuture,
        builder: (context, snapshot) {

          // 1. 로딩 상태
          if (snapshot.connectionState !=
              ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 2. 오류 상태
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Text(
                    '영화 정보를 불러오지 못했습니다.',
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: _reloadMovie,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          // 3. 데이터 확인
          final movie = snapshot.data;

          if (movie == null) {
            return const Center(
              child: Text('영화를 찾을 수 없습니다.'),
            );
          }

          // 4. 정상 데이터 표시
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                // 영화 포스터
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(16),
                  child: TmdbPosterImage(
                    posterPath: movie.posterPath,
                    width: double.infinity,
                    height: 420,
                  ),
                ),

                const SizedBox(height: 24),

                // 영화 제목
                Text(
                  movie.title,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // 개봉일
                Text(
                  movie.releaseDate ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 20),

                // TMDB 평균 평점
                Row(
                  children: [
                    RatingBarIndicator(
                      rating:
                          movie.voteAverage / 2,
                      itemCount: 5,
                      itemSize: 24,
                      itemBuilder: (context, index) {
                        return const Icon(
                          Icons.star,
                          color: Colors.amber,
                        );
                      },
                    ),

                    const SizedBox(width: 8),

                    Text(
                      (movie.voteAverage / 2)
                          .toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 영화 줄거리
                Text(
                  movie.overview.isEmpty
                      ? '줄거리 정보가 없습니다.'
                      : movie.overview,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                // 즐겨찾기 버튼
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        isFavorite = !isFavorite;
                      });

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            isFavorite
                                ? '즐겨찾기에 추가되었습니다.'
                                : '즐겨찾기에서 삭제되었습니다.',
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                    label: Text(
                      isFavorite
                          ? '즐겨찾기 삭제'
                          : '즐겨찾기 추가',
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 평점 남기기 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showRatingDialog(movie.id);
                    },
                    child: const Text('평점 남기기'),
                  ),
                ),

                // 내가 남긴 평점
                if (selectedRating > 0) ...[
                  const SizedBox(height: 16),

                  Text(
                    '내 평점: $selectedRating',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // 영화 상세 정보 다시 불러오기
  void _reloadMovie() {
    final movieId = int.tryParse(widget.movieId);

    if (movieId == null) return;

    setState(() {
      _movieFuture = context
          .read<TmdbMovieService>()
          .fetchMovieDetail(movieId);
    });
  }

  // 평점 Dialog
  void _showRatingDialog(int movieId) {
    double tempRating = selectedRating;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('평점 남기기'),

              content: MovieRatingInput(
                rating: tempRating,
                onRatingUpdate: (rating) {
                  setDialogState(() {
                    tempRating = rating;
                  });
                },
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('취소'),
                ),

                ElevatedButton(
                  onPressed: tempRating == 0
                      ? null
                      : () {
                          setState(() {
                            selectedRating = tempRating;
                          });

                          // TMDB 영화 ID 확인
                          debugPrint(
                            '평점 대상 TMDB 영화 ID: $movieId',
                          );

                          debugPrint(
                            '사용자 평점: $selectedRating',
                          );

                          Navigator.pop(dialogContext);

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                '평점 $selectedRating점이 저장되었습니다.',
                              ),
                            ),
                          );
                        },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
