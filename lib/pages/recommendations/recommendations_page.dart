import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_recommender_web/models/movie_model.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_notifier.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_state.dart';
import 'package:movie_recommender_web/notifiers/movie/movie_notifier.dart';
import 'package:movie_recommender_web/notifiers/movie/movie_state.dart';
import 'package:movie_recommender_web/theme/app_color.dart';
import 'package:movie_recommender_web/widgets/movie_card.dart';
import 'package:movie_recommender_web/widgets/state_widgets.dart';

class RecommendationsPage extends ConsumerStatefulWidget {
  const RecommendationsPage({super.key});

  @override
  ConsumerState<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends ConsumerState<RecommendationsPage> {
  // Frontend pins user-user CF — backend supports svd/item_item too but those
  // are evaluation baselines, not the production model.
  static const String _algorithm = 'user_user';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final MovieState movieState = ref.read(movieNotifierProvider);
      if (movieState.status == MovieStatus.initial) {
        ref.read(movieNotifierProvider.notifier).loadMovies();
      }
      final AuthState authState = ref.read(authNotifierProvider);
      if (authState.isAuthenticated && authState.user != null && movieState.recommendations.isEmpty) {
        _reload(authState.user!.id);
      }
    });
  }

  Future<void> _reload(int userId) async {
    setState(() => _loading = true);
    await ref.read(movieNotifierProvider.notifier).loadRecommendations(userId, algorithm: _algorithm);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final MovieState movieState = ref.watch(movieNotifierProvider);
    final AuthState authState = ref.watch(authNotifierProvider);
    final double screenWidth = MediaQuery.of(context).size.width;

    final int crossAxisCount = screenWidth > 1400
        ? 6
        : screenWidth > 1100
            ? 5
            : screenWidth > 800
                ? 4
                : screenWidth > 560
                    ? 3
                    : 2;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: RefreshIndicator(
        onRefresh: () async {
          if (authState.user != null) await _reload(authState.user!.id);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommendations',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Personalized picks from users with similar taste (User-User Collaborative Filtering).',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            if (_loading || movieState.status == MovieStatus.loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: AppLoadingView(message: 'Loading recommendations...'),
              )
            else if (!authState.isAuthenticated || authState.user == null)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Sign in to see personalized recommendations.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else if (movieState.recommendations.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.movie_filter_outlined, size: 56, color: AppColors.textTertiary),
                      const SizedBox(height: 12),
                      const Text(
                        'No recommendations yet.',
                        style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Rate a few movies to unlock personalized picks.',
                        style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => _reload(authState.user!.id),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.55,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final MovieModel movie = movieState.recommendations[index];
                      return LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          final double w = constraints.maxWidth;
                          return MovieCard(
                            movie: movie,
                            width: w,
                            height: w * 1.5,
                            onTap: () => context.push('/movie/${movie.movieId}'),
                          );
                        },
                      );
                    },
                    childCount: movieState.recommendations.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
