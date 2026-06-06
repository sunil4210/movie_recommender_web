import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_recommender_web/core/constants/app_constants.dart';
import 'package:movie_recommender_web/core/router/app_router.dart';
import 'package:movie_recommender_web/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Drop the leading `#/` from URLs on Flutter web so every route looks like
  // a normal path (e.g. /movie/123/reviews instead of /#/movie/123/reviews).
  // Requires the host to serve index.html for unknown paths — Flutter's dev
  // server already does this, and the typical static-host SPA fallback covers
  // production deploys.
  usePathUrlStrategy();
  runApp(const ProviderScope(child: CineMatchApp()));
}

class CineMatchApp extends ConsumerWidget {
  const CineMatchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.primaryTheme,
      routerConfig: router,
    );
  }
}
