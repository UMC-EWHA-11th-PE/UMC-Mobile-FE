import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/network/movie_log_client.dart';
import '../core/network/tmdb_client.dart';
import '../data/local/token_storage.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/learning_member_session.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({
    super.key,
    this.tmdbMovieService,
    this.signUpService,
    this.ratingApiService,
    this.learningMemberSession,
    this.authViewModel,
  });

  /// 테스트에서 가짜 TMDB 응답을 쓰기 위해 바꿔 넣을 수 있습니다. null이면 실제 TMDB를 호출합니다.
  final TmdbMovieService? tmdbMovieService;

  /// 테스트에서 가짜 중복 확인·회원가입 응답을 쓰기 위해 바꿔 넣을 수 있습니다. null이면 자체 서버를 호출합니다.
  final SignUpService? signUpService;

  /// 테스트에서 가짜 평점 조회·쓰기 응답을 쓰기 위해 바꿔 넣을 수 있습니다. null이면 자체 서버를 호출합니다.
  final RatingApiService? ratingApiService;

  /// 테스트에서 이미 가입한 학습용 회원으로 시작하기 위해 바꿔 넣을 수 있습니다.
  final LearningMemberSession? learningMemberSession;

  /// 테스트에서 가짜 로그인·내 정보 Service를 쓰는 세션으로 바꿔 넣을 수 있습니다.
  /// 이미 확인을 마친(initializing이 아닌) 세션이면 앱이 다시 복원하지 않습니다.
  final AuthViewModel? authViewModel;

  @override
  Widget build(BuildContext context) {
    // 워크북 Client는 공개용·보호용 두 개입니다. TMDB Client와는 계속 합치지 않습니다.
    final tokenStorage = SecureTokenStorage(const FlutterSecureStorage());
    final publicClient = createMovieLogClient(); // Interceptor 없음
    final authClient = createAuthMovieLogClient(tokenStorage); // Interceptor 등록
    final injectedAuth = authViewModel;

    // 여러 화면(Route)이 함께 쓰는 객체는 MaterialApp.router 위에 등록합니다.
    // Service는 상태가 없으므로 인스턴스 하나를 모든 ViewModel이 공유합니다.
    return MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        // 회원가입으로 얻은 학습용 memberId — 영화 상세·마이페이지 Route가 같은 값을 읽습니다.
        ChangeNotifierProvider<LearningMemberSession>(
          create: (_) => learningMemberSession ?? LearningMemberSession(),
        ),
        Provider<TmdbMovieService>(
          create: (_) =>
              tmdbMovieService ?? TmdbMovieService(createTmdbClient()),
        ),
        // 공개 Client
        Provider<AuthApiService>(create: (_) => AuthApiService(publicClient)),
        Provider<SignUpService>(
          create: (_) => signUpService ?? SignUpService(publicClient),
        ),
        // 보호 Client
        Provider<MemberApiService>(create: (_) => MemberApiService(authClient)),
        // 평점은 아직 v6(memberId path) — v7 보호 요청으로 옮길 때 authClient도 함께 받습니다.
        Provider<RatingApiService>(
          create: (_) => ratingApiService ?? RatingApiService(publicClient),
        ),
        // Service를 주입받는 ViewModel — redirect와 스플래시·로그인 화면이 함께 읽습니다.
        if (injectedAuth != null)
          ChangeNotifierProvider<AuthViewModel>.value(value: injectedAuth)
        else
          ChangeNotifierProvider<AuthViewModel>(
            create: (context) => AuthViewModel(
              context.read<AuthApiService>(),
              context.read<MemberApiService>(),
              context.read<TokenStorage>(),
            ),
          ),
      ],
      child: const _MovieLogRouterApp(),
    );
  }
}

/// GoRouter를 앱이 살아있는 동안 한 번만 만들기 위한 Stateful 호스트입니다.
///
/// build()에서 만들면 다시 그려질 때마다 Router가 새로 생겨 현재 위치가 초기화됩니다.
class _MovieLogRouterApp extends StatefulWidget {
  const _MovieLogRouterApp();

  @override
  State<_MovieLogRouterApp> createState() => _MovieLogRouterAppState();
}

class _MovieLogRouterAppState extends State<_MovieLogRouterApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authViewModel = context.read<AuthViewModel>();
    // 상태가 바뀔 때마다 redirect를 다시 계산하도록 Router에 세션을 연결합니다.
    _router = AppRouter.createRouter(authViewModel);
    // 첫 build 이후 재설치 정리 → 세션 복원을 시작합니다. 그동안 스플래시가 보입니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && authViewModel.status == AuthStatus.initializing) {
        authViewModel.initialize();
      }
    });
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
