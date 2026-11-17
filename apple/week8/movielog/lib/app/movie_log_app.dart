import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/network/auth_token_interceptor.dart';
import '../core/network/movie_log_client.dart';
import '../core/network/tmdb_client.dart';
import '../data/local/auth_token_storage.dart';
import '../data/services/member_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/learning_member_session.dart';

class MovieLogApp extends StatefulWidget {
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

  /// 테스트에서 이미 로그인(또는 로그아웃)된 세션으로 시작하기 위해 바꿔 넣을 수 있습니다.
  /// 넘기면 [AuthViewModel.initialize]를 앱이 대신 부르지 않습니다.
  final AuthViewModel? authViewModel;

  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  late final Dio _movieLogClient;
  late final AuthViewModel _auth;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // 회원가입·로그인·평점은 같은 워크북 백엔드라 Dio 하나를 함께 씁니다.
    // 보호 요청에만 MovieLog JWT를 붙이는 Interceptor는 이 Client에만 추가합니다.
    const tokenStorage = AuthTokenStorage();
    _movieLogClient = createMovieLogClient()
      ..interceptors.insert(0, AuthTokenInterceptor(tokenStorage));

    final injected = widget.authViewModel;
    _auth =
        injected ??
        AuthViewModel(tokenStorage, MemberApiService(_movieLogClient));
    // 앱이 만든 세션만 여기서 복원을 시작합니다. 첫 화면은 스플래시(initializing)입니다.
    if (injected == null) _auth.initialize();

    // 상태가 바뀔 때마다 redirect를 다시 계산하도록 Router에 세션을 연결합니다.
    _router = AppRouter.create(_auth);
  }

  @override
  void dispose() {
    _router.dispose();
    // 테스트가 넘긴 세션은 넘긴 쪽이 정리합니다.
    if (widget.authViewModel == null) _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final movieLogClient = _movieLogClient;
    final tmdbMovieService = widget.tmdbMovieService;
    final signUpService = widget.signUpService;
    final ratingApiService = widget.ratingApiService;
    final learningMemberSession = widget.learningMemberSession;

    // 여러 화면(Route)이 함께 쓰는 객체는 MaterialApp.router 위에 등록합니다.
    // Service는 상태가 없으므로 인스턴스 하나를 모든 ViewModel이 공유합니다.
    return MultiProvider(
      providers: [
        // MovieLog 로그인 세션 — redirect와 스플래시·로그인 화면이 함께 읽습니다.
        ChangeNotifierProvider<AuthViewModel>.value(value: _auth),
        // 회원가입으로 얻은 학습용 memberId — 영화 상세·마이페이지 Route가 같은 값을 읽습니다.
        ChangeNotifierProvider<LearningMemberSession>(
          create: (_) => learningMemberSession ?? LearningMemberSession(),
        ),
        Provider<TmdbMovieService>(
          create: (_) =>
              tmdbMovieService ?? TmdbMovieService(createTmdbClient()),
        ),
        Provider<SignUpService>(
          create: (_) => signUpService ?? SignUpService(movieLogClient),
        ),
        Provider<RatingApiService>(
          create: (_) => ratingApiService ?? RatingApiService(movieLogClient),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'MovieLog',
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
