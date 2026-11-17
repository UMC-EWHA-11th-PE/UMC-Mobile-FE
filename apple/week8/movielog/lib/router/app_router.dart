import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/member_api_service.dart';
import '../data/services/sign_up_service.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import '../models/movie_detail.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_page_screen.dart';
import '../screens/my_ratings_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/splash_screen.dart';
import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/my_ratings_view_model.dart';
import '../view_models/session_rating_store.dart';
import '../view_models/sign_up_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';

/// 로그인 상태와 이동하려는 경로를 보고, 다른 경로로 보내야 하면 그 경로를 돌려줍니다.
///
/// redirect 안에서는 상태만 읽고 판단합니다. API 호출 같은 비동기 작업은 하지 않습니다.
String? authRedirect(AuthStatus status, String location) {
  const publicPaths = {'/login', '/register'};
  final atStart = location == '/start';
  final atPublic = publicPaths.contains(location);

  return switch (status) {
    // 토큰 확인 중 또는 확인 실패(재시도 버튼): 스플래시 화면 유지
    AuthStatus.initializing ||
    AuthStatus.retryRequired => atStart ? null : '/start',
    // 로그아웃 또는 로그인 요청 중: 공개 화면만 허용
    AuthStatus.signedOut ||
    AuthStatus.authenticating => atPublic ? null : '/login',
    // 로그인됨: 스플래시와 로그인·회원가입 화면은 홈으로 보냄
    AuthStatus.signedIn => (atStart || atPublic) ? '/home' : null,
  };
}

/// 앱에서 사용하는 Route를 한곳에서 관리하는 클래스
class AppRouter {
  AppRouter._();

  /// [auth]의 상태가 바뀔 때마다(refreshListenable) redirect를 다시 계산합니다.
  ///
  /// 앱(MovieLogApp)마다 한 번 만들어, 테스트끼리 이동 기록·Navigator key를 공유하지 않습니다.
  static GoRouter createRouter(AuthViewModel auth) {
    // root Navigator — 하단 탭(ShellRoute) 바깥에 전체 화면으로 띄울 Route가 사용합니다.
    final rootNavigatorKey = GlobalKey<NavigatorState>();

    return GoRouter(
      initialLocation: '/start',
      navigatorKey: rootNavigatorKey,
      refreshListenable: auth,
      redirect: (context, state) => authRedirect(auth.status, state.uri.path),
      routes: [
        // 스플래시 — 확인 중에는 로딩, 확인 실패(retryRequired)면 다시 시도 버튼
        GoRoute(
          path: '/start',
          builder: (context, state) => Consumer<AuthViewModel>(
            builder: (context, auth, _) => SplashScreen(
              message: auth.message,
              onRetry: auth.status == AuthStatus.retryRequired
                  ? auth.initialize
                  : null,
            ),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => ChangeNotifierProvider<SignUpViewModel>(
            create: (context) => SignUpViewModel(context.read<SignUpService>()),
            child: const RegisterScreen(),
          ),
        ),
        // 영화 상세 — 하단 탭 없이 전체 화면으로 표시 (예: /movies/969681)
        // 경로의 movieId는 TMDB id이고, ViewModel이 TMDB 상세를 불러옵니다.
        // 상세 정보를 extra로 함께 받으면(홈 추천 신작 Mock) 그대로 보여줍니다.
        // 평점 등록은 path의 TMDB id만 보내고 회원은 서버가 JWT로 식별합니다. (memberId 없음)
        // 등록 응답의 평점은 이번 로그인 세션의 "내가 등록한 평점"에 보관합니다.
        GoRoute(
          path: '/movies/:movieId',
          builder: (context, state) {
            final movieId = int.tryParse(state.pathParameters['movieId'] ?? '');
            final detail = state.extra;
            if (detail is MovieDetail) {
              return MovieDetailScreen(movieId: movieId, detail: detail);
            }
            // 목록·홈에서 넘긴 TmdbMovieDto는 경로 id와 같을 때만 씁니다.
            // 직접 접근·Deep Link처럼 extra가 없으면 TMDB 상세를 다시 조회합니다.
            final initialMovie = detail is TmdbMovieDto && detail.id == movieId
                ? detail
                : null;
            return ChangeNotifierProvider<MovieDetailViewModel>(
              create: (context) => MovieDetailViewModel(
                context.read<TmdbMovieService>(),
                movieId: movieId,
                initialMovie: initialMovie,
                ratingService: context.read<RatingApiService>(),
                onRatingCreated: (rating) => context
                    .read<SessionRatingStore>()
                    .upsert(auth.sessionVersion, rating),
                onSessionExpired: auth.expireSession,
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
              routes: [
                // 프로필 수정 (최종 경로 /my/profile/edit) — 하단 탭 없이 위에 띄웁니다.
                // 마이페이지 수정 버튼은 member가 있을 때만 켜지지만, 직접 접근에 대비해
                // 내 정보가 아직 없으면 불러오기·다시 시도 화면을 먼저 보여줍니다.
                GoRoute(
                  path: 'profile/edit',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final auth = context.watch<AuthViewModel>();
                    if (auth.member == null) {
                      return Scaffold(
                        appBar: const CommonAppBar(
                          title: '프로필 수정',
                          titleStyle: AppTheme.appBarTitleBold,
                        ),
                        body: Center(
                          child: auth.memberStatus == MemberLoadStatus.error
                              ? MovieLogButton(
                                  label: '다시 시도',
                                  onPressed: () => auth.loadMember(force: true),
                                )
                              : const CircularProgressIndicator(),
                        ),
                      );
                    }
                    return ChangeNotifierProvider<EditProfileViewModel>(
                      create: (context) => EditProfileViewModel(
                        context.read<MemberApiService>(),
                        auth,
                      ),
                      child: const EditProfileScreen(),
                    );
                  },
                ),
                // 내가 등록한 평점 (최종 경로 /my/ratings)
                // root Navigator 위에 push해 하단 NavigationBar를 가립니다.
                // 8주차 — 이번 세션 등록분 + 같은 계정으로 가입했으면 공개 조회(memberId)를 합칩니다.
                // 다른 계정의 memberId는 쓰지 않습니다. 쓰기는 모두 JWT로 보냅니다.
                GoRoute(
                  path: 'ratings',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final memberId = context
                        .read<LearningMemberSession>()
                        .memberIdFor(auth.member?.email);
                    return ChangeNotifierProvider<MyRatingsViewModel>(
                      create: (context) => MyRatingsViewModel(
                        context.read<RatingApiService>(),
                        context.read<TmdbMovieService>(),
                        memberId: memberId,
                        sessionRatings: context.read<SessionRatingStore>(),
                        sessionVersion: auth.sessionVersion,
                        onSessionExpired: auth.expireSession,
                      )..load(),
                      child: const MyRatingsScreen(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static int indexFromLocation(String path) {
    if (path.startsWith('/movies')) return 1;
    if (path.startsWith('/my')) return 2;

    return 0;
  }
}
