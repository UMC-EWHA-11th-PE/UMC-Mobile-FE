import 'package:go_router/go_router.dart';

import '../register_screen.dart';
import '../start_screen.dart';

/// 앱에서 사용하는 Route를 한곳에서 관리하는 클래스
class AppRouter {
  AppRouter._();

  // Route 경로
  static const String startPath = '/';
  static const String registerPath = '/register';

  // Route 이름 (context.goNamed / pushNamed 에서 사용)
  static const String startName = 'start';
  static const String registerName = 'register';

  static final GoRouter router = GoRouter(
    // 앱을 처음 실행했을 때 보여줄 경로
    initialLocation: startPath,
    // 라우팅 로그를 콘솔에 출력 (개발 중 확인용)
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: startPath,
        name: startName,
        builder: (context, state) => const StartScreen(),
      ),
      GoRoute(
        path: registerPath,
        name: registerName,
        builder: (context, state) => const RegisterScreen(),
      ),
    ],
  );
}
