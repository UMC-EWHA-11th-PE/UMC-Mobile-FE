import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/services/member_check_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../models/movie_detail.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_page_screen.dart';
import '../screens/register_screen.dart';
import '../screens/start_screen.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/sign_up_view_model.dart';

/// 앱에서 사용하는 Route를 한곳에서 관리하는 클래스
class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    // 자체 서버(회원가입 중복 확인) 연결 전까지는 시작·회원가입을 건너뛰고 홈에서 시작합니다.
    // 서버를 연결하면 '/start'로 되돌립니다.
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
          create: (context) =>
              SignUpViewModel(context.read<MemberCheckService>()),
          child: const RegisterScreen(),
        ),
      ),
      // 영화 상세 — 하단 탭 없이 전체 화면으로 표시 (예: /movies/969681)
      // 경로의 movieId는 TMDB id이고, ViewModel이 TMDB 상세를 불러옵니다.
      // 상세 정보를 extra로 함께 받으면(홈 추천 신작 Mock) 그대로 보여줍니다.
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) {
          final movieId = int.tryParse(state.pathParameters['movieId'] ?? '');
          final detail = state.extra;
          if (detail is MovieDetail) {
            return MovieDetailScreen(movieId: movieId, detail: detail);
          }
          return ChangeNotifierProvider<MovieDetailViewModel>(
            create: (context) => MovieDetailViewModel(
              context.read<TmdbMovieService>(),
              movieId: movieId,
            )..load(),
            child: MovieDetailScreen(movieId: movieId),
          );
        },
      ),
      // 하단 탭(홈/영화/마이)을 공유하는 화면들
      ShellRoute(
        builder: (context, state, child) {
          return MainScreen(
            currentIndex: indexFromLocation(state.uri.path),
            child: child,
          );
        },
        routes: [
          // 화면마다 ViewModel을 따로 만들고, 화면을 벗어나면 dispose합니다.
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                ChangeNotifierProvider<MovieHomeViewModel>(
                  create: (context) =>
                      MovieHomeViewModel(context.read<TmdbMovieService>())
                        ..loadPopular(),
                  child: const HomeScreen(),
                ),
          ),
          GoRoute(
            path: '/movies',
            builder: (context, state) =>
                ChangeNotifierProvider<MovieListViewModel>(
                  create: (context) =>
                      MovieListViewModel(context.read<TmdbMovieService>())
                        ..loadInitial(),
                  child: const MovieListScreen(),
                ),
          ),
          GoRoute(
            path: '/my',
            builder: (context, state) => const MyPageScreen(),
          ),
        ],
      ),
    ],
  );

  static int indexFromLocation(String path) {
    if (path.startsWith('/movies')) return 1;
    if (path.startsWith('/my')) return 2;

    return 0;
  }
}
