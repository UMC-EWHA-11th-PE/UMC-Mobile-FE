import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/network/api_client.dart';
import '../core/network/tmdb_client.dart';
import '../data/services/member_check_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({
    super.key,
    this.tmdbMovieService,
    this.memberCheckService,
    this.ratingApiService,
  });

  /// 테스트에서 가짜 TMDB 응답을 쓰기 위해 바꿔 넣을 수 있습니다. null이면 실제 TMDB를 호출합니다.
  final TmdbMovieService? tmdbMovieService;

  /// 테스트에서 가짜 중복 확인 응답을 쓰기 위해 바꿔 넣을 수 있습니다. null이면 자체 서버를 호출합니다.
  final MemberCheckService? memberCheckService;

  /// 테스트에서 가짜 평점 조회 응답을 쓰기 위해 바꿔 넣을 수 있습니다. null이면 자체 서버를 호출합니다.
  final RatingApiService? ratingApiService;

  @override
  Widget build(BuildContext context) {
    // 여러 화면(Route)이 함께 쓰는 객체는 MaterialApp.router 위에 등록합니다.
    // Service는 상태가 없으므로 인스턴스 하나를 모든 ViewModel이 공유합니다.
    return MultiProvider(
      providers: [
        Provider<TmdbMovieService>(
          create: (_) =>
              tmdbMovieService ?? TmdbMovieService(createTmdbClient()),
        ),
        Provider<MemberCheckService>(
          create: (_) =>
              memberCheckService ?? MemberCheckService(createApiClient()),
        ),
        Provider<RatingApiService>(
          create: (_) =>
              ratingApiService ?? RatingApiService(createApiClient()),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MovieLog',
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
