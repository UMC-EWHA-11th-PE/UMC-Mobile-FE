import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../screen/start_screen.dart';
import '../screen/signup_screen.dart';
import '../screen/home_screen.dart';
import '../screen/main_screen.dart';
import '../screen/movie_list_screen.dart';
import '../screen/movie_detail_screen.dart';
import '../screen/profile_screen.dart';

import '../data/services/tmdb_movie_service.dart';
import '../view_models/movie_list_view_model.dart';

// MovieHomeViewModel import에 별칭 추가
import '../view_models/movie_home_view_model.dart' as home_vm;

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/start',
    routes: [
      // 0주차 시작 화면
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),

      // 1주차 회원가입 화면
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),

      // 홈 / 영화 / 마이 공통 NavigationBar
      ShellRoute(
        builder: (context, state, child) {
          return MainScreen(
            currentIndex: indexFromLocation(state.uri.path),
            child: child,
          );
        },
        routes: [
          // 홈 화면
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                ChangeNotifierProvider<home_vm.MovieHomeViewModel>(
                  create: (context) => home_vm.MovieHomeViewModel(
                    context.read<TmdbMovieService>(),
                  )..loadPopular(),
                  child: const HomeScreen(),
                ),
          ),

          // 영화 목록 화면
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

          // 마이페이지
          GoRoute(
            path: '/my',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // 영화 상세 화면
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) {
          return MovieDetailScreen(movieId: state.pathParameters['movieId']!);
        },
      ),
    ],
  );

  static int indexFromLocation(String path) {
    if (path == '/movies') {
      return 1;
    }

    if (path == '/my') {
      return 2;
    }

    return 0;
  }
}
