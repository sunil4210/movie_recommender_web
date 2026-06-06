import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_notifier.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_state.dart';
import 'package:movie_recommender_web/pages/auth/login_page.dart';
import 'package:movie_recommender_web/pages/auth/register_page.dart';
import 'package:movie_recommender_web/pages/auth/forgot_password_page.dart';
import 'package:movie_recommender_web/pages/auth/verify_otp_page.dart';
import 'package:movie_recommender_web/pages/auth/reset_password_page.dart';
import 'package:movie_recommender_web/pages/home/home_page.dart';
import 'package:movie_recommender_web/pages/recommendations/recommendations_page.dart';
import 'package:movie_recommender_web/pages/search/search_page.dart';
import 'package:movie_recommender_web/pages/favorites/favorites_page.dart';
import 'package:movie_recommender_web/pages/profile/profile_page.dart';
import 'package:movie_recommender_web/pages/movie/movie_details_page.dart';
import 'package:movie_recommender_web/pages/movie/movie_reviews_page.dart';
import 'package:movie_recommender_web/pages/onboarding/onboarding_page.dart';
import 'package:movie_recommender_web/pages/shell/app_shell.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String recommendations = '/recommendations';
  static const String search = '/search';
  static const String favorites = '/favorites';
  static const String profile = '/profile';
  static const String movieDetails = '/movie/:movieId';
  static const String movieReviews = '/movie/:movieId/reviews';
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
      GoRoute(
        path: AppRoutes.verifyOtp,
        builder: (BuildContext context, GoRouterState state) {
          final Map<String, String> q = state.uri.queryParameters;
          final String email = q['email'] ?? '';
          final String purpose = q['purpose'] ?? 'signup';
          if (email.isEmpty) {
            return const LoginPage();
          }
          return VerifyOtpPage(email: email, purpose: purpose);
        },
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          if (extra is Map<String, String> &&
              extra['email'] != null &&
              extra['code'] != null) {
            return ResetPasswordPage(
              email: extra['email']!,
              code: extra['code']!,
            );
          }
          return const LoginPage();
        },
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
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          final String movieId = state.pathParameters['movieId']!;
          return MovieDetailsPage(movieId: movieId);
        },
      ),
      GoRoute(
        path: AppRoutes.movieReviews,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) {
          final String movieId = state.pathParameters['movieId']!;
          return MovieReviewsPage(movieId: movieId);
        },
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state) => const OnboardingPage(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final AuthState authState = ref.read(authNotifierProvider);
      final bool isAuthenticated = authState.isAuthenticated;
      final String loc = state.matchedLocation;
      final bool isAuthRoute = loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.forgotPassword ||
          loc == AppRoutes.verifyOtp ||
          loc == AppRoutes.resetPassword;
      final bool isOnboarding = loc == AppRoutes.onboarding;

      // Not signed in: only auth routes allowed.
      if (!isAuthenticated) {
        if (isAuthRoute || authState.status == AuthStatus.initial) {
          return null;
        }
        return AppRoutes.login;
      }

      // Signed in. Send new users (no ratings) to onboarding from anywhere
      // except the onboarding screen itself.
      final bool isNewUser = authState.user != null &&
          authState.user!.totalRatings == 0;
      if (isNewUser && !isOnboarding) {
        return AppRoutes.onboarding;
      }

      // Existing users hitting an auth screen or onboarding go home.
      if (!isNewUser && (isAuthRoute || isOnboarding)) {
        return AppRoutes.home;
      }

      return null;
    },
  );
});
