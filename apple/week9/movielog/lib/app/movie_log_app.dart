import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/network/movie_log_client.dart';
import '../core/network/tmdb_client.dart';
import '../core/session/auth_session_bridge.dart';
import '../core/session/session_guard.dart';
import '../data/local/token_storage.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/member_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/session_rating_store.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({
    super.key,
    this.tmdbMovieService,
    this.signUpService,
    this.ratingApiService,
    this.learningMemberSession,
    this.memberApiService,
    this.authViewModel,
    this.favoriteApiService,
  });

  /// 테스트에서 가짜 TMDB 응답을 쓰기 위해 바꿔 넣을 수 있습니다. null이면 실제 TMDB를 호출합니다.
  final TmdbMovieService? tmdbMovieService;

  /// 테스트에서 가짜 중복 확인·회원가입 응답을 쓰기 위해 바꿔 넣을 수 있습니다. null이면 자체 서버를 호출합니다.
  final SignUpService? signUpService;

  /// 테스트에서 가짜 평점 조회·쓰기 응답을 쓰기 위해 바꿔 넣을 수 있습니다. null이면 자체 서버를 호출합니다.
  final RatingApiService? ratingApiService;

  /// 테스트에서 이미 가입한 학습용 회원으로 시작하기 위해 바꿔 넣을 수 있습니다.
  final LearningMemberSession? learningMemberSession;

  /// 테스트에서 가짜 내 정보 조회·수정 응답을 쓰기 위해 바꿔 넣을 수 있습니다. null이면 자체 서버를 호출합니다.
  final MemberApiService? memberApiService;

  /// 테스트에서 가짜 로그인·내 정보 Service를 쓰는 세션으로 바꿔 넣을 수 있습니다.
  /// 이미 확인을 마친(initializing이 아닌) 세션이면 앱이 다시 복원하지 않습니다.
  final AuthViewModel? authViewModel;

  /// 테스트에서 가짜 즐겨찾기 응답을 쓰기 위해 바꿔 넣을 수 있습니다. null이면 자체 서버를 호출합니다.
  final FavoriteApiService? favoriteApiService;

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
        // 이 앱에서 가입한 계정의 memberId(+email) — 같은 계정일 때만 공개 평점 조회에 씁니다.
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
        Provider<MemberApiService>(
          create: (_) => memberApiService ?? MemberApiService(authClient),
        ),
        // 평점 — 공개 조회는 publicClient, 등록·수정·삭제는 authClient (Service가 메서드별로 결정)
        Provider<RatingApiService>(
          create: (_) =>
              ratingApiService ?? RatingApiService(publicClient, authClient),
        ),
        // 즐겨찾기 — 등록·목록·여부·해제 모두 보호 요청 (9주차)
        Provider<FavoriteApiService>(
          create: (_) => favoriteApiService ?? FavoriteApiService(authClient),
        ),
        // 이번 로그인 세션에서 등록·수정한 평점 (v8에도 토큰 기반 내 평점 목록 GET이 없음)
        Provider<SessionRatingStore>(create: (_) => SessionRatingStore()),
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
        // 9주차 — AuthViewModel의 sessionVersion·검증된 email을 SessionGuard로 전달합니다.
        // 응답이 도착했을 때 "지금 로그인한 그 세션의 것인지"를 이 guard로 판정합니다.
        Provider<AuthSessionBridge>(
          // 앱이 시작될 때부터 세션 변화를 따라가도록 바로 만듭니다.
          lazy: false,
          create: (context) {
            final auth = context.read<AuthViewModel>();
            return AuthSessionBridge(
              authSignals: auth,
              sessionVersion: () => auth.sessionVersion,
              verifiedEmail: () => auth.status == AuthStatus.signedIn
                  ? auth.member?.email
                  : null,
            );
          },
          dispose: (_, bridge) => bridge.dispose(),
        ),
        Provider<SessionGuard>(
          create: (context) => context.read<AuthSessionBridge>().guard,
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
