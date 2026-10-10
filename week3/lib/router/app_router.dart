import 'package:go_router/go_router.dart';

import '../screen/start_screen.dart';
import '../screen/signup_screen.dart';
import '../screen/home_screen.dart';
import '../screen/main_screen.dart';
import '../screen/movie_list_screen.dart';
import '../screen/movie_detail_screen.dart';
import '../screen/profile_screen.dart';

class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/start',
    routes: [
      // 0주차 시작 화면
      GoRoute(
        path: '/start',
        builder: (context, state) => const StartScreen(),
      ),

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
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),

          GoRoute(
            path: '/movies',
            builder: (context, state) => const MovieListScreen(),
          ),

          GoRoute(
            path: '/my',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // 영화 상세
      GoRoute(
        path: '/movies/:movieId',
        builder: (context, state) {
          return MovieDetailScreen(
            movieId: state.pathParameters['movieId']!,
          );
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
