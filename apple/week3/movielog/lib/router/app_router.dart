import 'package:go_router/go_router.dart';

import '../home_screen.dart';
import '../main_screen.dart';
import '../movie_detail_screen.dart';
import '../movie_list_screen.dart';
import '../my_page_screen.dart';
import '../register_screen.dart';
import '../start_screen.dart';

/// 앱에서 사용하는 Route를 한곳에서 관리하는 클래스
class AppRouter {
  AppRouter._();

  static final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // 영화 상세 — 하단 탭 없이 전체 화면으로 표시 (예: /movies/1)
      GoRoute(
        path: '/movies/:id',
        builder: (context, state) => MovieDetailScreen(
          movieId: int.tryParse(state.pathParameters['id'] ?? ''),
        ),
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
