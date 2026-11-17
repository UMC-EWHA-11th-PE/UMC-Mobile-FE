import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/network/movie_log_client.dart';
import '../core/network/tmdb_client.dart';
import '../core/storage/token_storage.dart';
import '../data/services/auth_api_service.dart';
import '../data/services/member_api_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/session_ratings_view_model.dart';

class MovieLogApp extends StatefulWidget {
  const MovieLogApp({super.key});

  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  // build()마다 Client가 새로 만들어지지 않도록 State에서 한 번만 만듭니다.
  final TokenStorage _tokenStorage = SecureTokenStorage(
    const FlutterSecureStorage(),
  );
  late final _publicClient = createMovieLogClient(); // Interceptor 없음
  late final _authClient = createAuthMovieLogClient(_tokenStorage); // JWT 부착

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: _tokenStorage),
        // TMDB Client: TMDB Read Access Token만 사용 (MovieLog JWT와 섞지 않음)
        Provider<TmdbMovieService>(
          create: (_) => TmdbMovieService(createTmdbClient()),
        ),
        // 공개 Client
        Provider<AuthApiService>(
          create: (_) => AuthApiService(_publicClient),
        ),
        // 보호 Client
        Provider<MemberApiService>(
          create: (_) => MemberApiService(_authClient),
        ),
        // 조회는 공개, 등록·수정·삭제는 보호 Client
        Provider<RatingApiService>(
          create: (_) => RatingApiService(_publicClient, _authClient),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthApiService>(),
            context.read<MemberApiService>(),
            context.read<TokenStorage>(),
          ),
        ),
        ChangeNotifierProvider<SessionRatingsViewModel>(
          create: (context) => SessionRatingsViewModel(
            context.read<RatingApiService>(),
            context.read<AuthViewModel>(),
          ),
        ),
      ],
      child: const _MovieLogRouterApp(),
    );
  }
}

/// GoRouter는 앱이 살아있는 동안 한 번만 만들어야 하므로 별도 StatefulWidget으로 분리합니다.
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
    _router = AppRouter.createRouter(authViewModel);
    // 첫 build 이후 세션 복원을 시작합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) authViewModel.restoreSession();
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.violet),
        scaffoldBackgroundColor: AppColors.warmWhite,
      ),
      routerConfig: _router,
    );
  }
}
