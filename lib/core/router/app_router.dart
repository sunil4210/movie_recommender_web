import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_notifier.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_state.dart';
import 'package:movie_recommender_web/pages/auth/login_page.dart';
import 'package:movie_recommender_web/pages/auth/register_page.dart';
import 'package:movie_recommender_web/pages/auth/forgot_password_page.dart';
import 'package:movie_recommender_web/pages/home/home_page.dart';
import 'package:movie_recommender_web/pages/recommendations/recommendations_page.dart';
import 'package:movie_recommender_web/pages/search/search_page.dart';
import 'package:movie_recommender_web/pages/favorites/favorites_page.dart';
import 'package:movie_recommender_web/pages/profile/profile_page.dart';
import 'package:movie_recommender_web/pages/movie/movie_details_page.dart';
import 'package:movie_recommender_web/pages/filter/filter_movies_page.dart';
import 'package:movie_recommender_web/pages/onboarding/onboarding_page.dart';
import 'package:movie_recommender_web/pages/shell/app_shell.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String recommendations = '/recommendations';
  static const String search = '/search';
  static const String favorites = '/favorites';
  static const String profile = '/profile';
  static const String movieDetails = '/movie/:movieId';
  static const String filter = '/filter';
  static const String onboarding = '/onboarding';
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(this._ref) {
    _sub = _ref.listen<AuthState>(
      authNotifierProvider,
      (AuthState? _, AuthState __) => notifyListeners(),
      fireImmediately: false,
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

final Provider<GoRouter> routerProvider = Provider<GoRouter>((Ref ref) {
  final _AuthRouterRefresh refresh = _AuthRouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.login,
    refreshListenable: refresh,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.login,
        builder: (BuildContext context, GoRouterState state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (BuildContext context, GoRouterState state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (BuildContext context, GoRouterState state) => const ForgotPasswordPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return AppShell(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (BuildContext context, GoRouterState state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.recommendations,
            pageBuilder: (BuildContext context, GoRouterState state) => const NoTransitionPage(
              child: RecommendationsPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.search,
            pageBuilder: (BuildContext context, GoRouterState state) => const NoTransitionPage(
              child: SearchPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.favorites,
            pageBuilder: (BuildContext context, GoRouterState state) => const NoTransitionPage(
              child: FavoritesPage(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (BuildContext context, GoRouterState state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.movieDetails,
        builder: (BuildContext context, GoRouterState state) {
          final String movieId = state.pathParameters['movieId']!;
          return MovieDetailsPage(movieId: movieId);
        },
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (BuildContext context, GoRouterState state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.filter,
        builder: (BuildContext context, GoRouterState state) => const FilterMoviesPage(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final AuthState authState = ref.read(authNotifierProvider);
      final bool isAuthenticated = authState.isAuthenticated;
      final bool isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register ||
          state.matchedLocation == AppRoutes.forgotPassword;

      if (isAuthenticated && isAuthRoute) {
        // New user with no ratings → onboarding
        final bool isNewUser = authState.user != null &&
            authState.user!.totalRatings == 0;
        return isNewUser ? AppRoutes.onboarding : AppRoutes.home;
      }

      if (!isAuthenticated && !isAuthRoute && authState.status != AuthStatus.initial) {
        return AppRoutes.login;
      }

      return null;
    },
  );
});
