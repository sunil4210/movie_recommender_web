import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_recommender_web/core/router/app_router.dart';
import 'package:movie_recommender_web/models/movie_model.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_notifier.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_state.dart';
import 'package:movie_recommender_web/notifiers/movie/movie_notifier.dart';
import 'package:movie_recommender_web/notifiers/movie/movie_state.dart';
import 'package:movie_recommender_web/services/service_providers.dart';
import 'package:movie_recommender_web/services/toast_service.dart';
import 'package:movie_recommender_web/theme/app_color.dart';
import 'package:movie_recommender_web/widgets/movie_poster.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final Set<int> _likedMovieIds = {};
  bool _submitting = false;

  static const int _minLikes = 3;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final MovieState movieState = ref.read(movieNotifierProvider);
      if (movieState.status == MovieStatus.initial) {
        ref.read(movieNotifierProvider.notifier).loadMovies();
      }
    });
  }

  Future<void> _submit() async {
    final AuthState authState = ref.read(authNotifierProvider);
    if (!authState.isAuthenticated || authState.user == null) return;

    setState(() => _submitting = true);

    final int userId = authState.user!.id;
    final ratingService = ref.read(ratingServiceProvider);

    // One bad request shouldn't break onboarding — count successes and only
    // bail when *every* rating submit failed.
    int succeeded = 0;
    for (final int movieId in _likedMovieIds) {
      final result = await ratingService.submit(
        userId: userId,
        movieId: movieId,
        rating: 5.0,
      );
      result.when(success: (_) => succeeded++, failure: (_) {});
    }

    if (succeeded == 0) {
      if (mounted) {
        setState(() => _submitting = false);
        ToastService.instance.show(
          context: context,
          title: "Couldn't save your picks. Check connection and try again.",
          toastType: ToastType.error,
        );
      }
      return;
    }

    // Pull fresh user (totalRatings > 0 now) so the router stops redirecting
    // back to onboarding, then warm the recommendations cache before navigating.
    await ref.read(authNotifierProvider.notifier).refreshUser();
    await ref
        .read(movieNotifierProvider.notifier)
        .loadRecommendations(userId, algorithm: 'user_user');

    if (!mounted) return;
    ToastService.instance.show(
      context: context,
      title: 'Great picks! Here are your recommendations',
      toastType: ToastType.success,
    );
    context.go(AppRoutes.home);
  }

  Future<void> _skip() async {
    // Even when skipping, refresh the user so the router doesn't bounce them
    // back here on every navigation. The cold-start path returns popular
    // movies as a placeholder until they rate something.
    await ref.read(authNotifierProvider.notifier).refreshUser();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final MovieState movieState = ref.watch(movieNotifierProvider);
    final AuthState authState = ref.watch(authNotifierProvider);
    final int remaining = _minLikes - _likedMovieIds.length;

    // Broaden the pool from popular+trending (~20 items, same for everyone) to
    // the full catalog so different users (and the same user across visits) see
    // varied options. Popular and trending stay at the front as "safe" picks,
    // then the rest of the catalog is shuffled with a per-user seed so the
    // order is stable across rebuilds within a session.
    final List<MovieModel> moviePool = [
      ...movieState.popularMovies,
      ...movieState.trendingMovies,
      ...movieState.allMovies,
    ];

    // Deduplicate while preserving the leading popular/trending order.
    final Set<int> seen = {};
    final List<MovieModel> deduped = moviePool.where((MovieModel m) {
      if (seen.contains(m.id)) return false;
      seen.add(m.id);
      return true;
    }).toList();

    // Seed the shuffle by user id so each user gets a different rotation but
    // the order doesn't jump around on every setState.
    final int seed = authState.user?.id ?? DateTime.now().millisecondsSinceEpoch;
    final List<MovieModel> remainder = deduped.sublist(
      deduped.length > 6 ? 6 : deduped.length,
    )..shuffle(Random(seed));
    final List<MovieModel> movies = [
      ...deduped.take(deduped.length > 6 ? 6 : deduped.length),
      ...remainder,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
            child: Column(
              children: [
                Text(
                  authState.user?.firstName != null &&
                          authState.user!.firstName!.isNotEmpty
                      ? 'Welcome, ${authState.user!.firstName}!'
                      : 'Welcome to CineMatch',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pick a few movies you like so we can tailor your feed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  remaining > 0
                      ? '$remaining more to unlock personalised picks  ·  takes ~20 sec'
                      : "All set — tap CONTINUE or pick a few more if you'd like.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Progress indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_minLikes, (int i) {
                    final bool filled = i < _likedMovieIds.length;
                    return Container(
                      width: 32,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: filled ? AppColors.primary : AppColors.grey300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Movie grid
          Expanded(
            child: movieState.status == MovieStatus.loading
                ? const Center(child: CircularProgressIndicator())
                : movies.isEmpty
                    ? const Center(
                        child: Text(
                          'Loading movies...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          childAspectRatio: 0.55,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: movies.length,
                        itemBuilder: (BuildContext context, int index) {
                          final MovieModel movie = movies[index];
                          final bool isLiked = _likedMovieIds.contains(movie.id);
                          return _OnboardingMovieCard(
                            movie: movie,
                            isLiked: isLiked,
                            onTap: () {
                              setState(() {
                                if (isLiked) {
                                  _likedMovieIds.remove(movie.id);
                                } else {
                                  _likedMovieIds.add(movie.id);
                                }
                              });
                            },
                          );
                        },
                      ),
          ),

          // Bottom bar with continue button
          Container(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF2A2A2A), width: 1),
              ),
            ),
            child: Row(
              children: [
                // Skip button — equal weight with CONTINUE so users who want
                // to explore first don't feel trapped.
                OutlinedButton(
                  onPressed: _submitting ? null : _skip,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: Color(0xFF3A3A3A)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'BROWSE FIRST',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                // Selected count
                if (_likedMovieIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      '${_likedMovieIds.length} selected',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                // Continue button
                ElevatedButton(
                  onPressed: _likedMovieIds.length >= _minLikes && !_submitting
                      ? _submit
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.grey300,
                    disabledForegroundColor: AppColors.textDisabled,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'CONTINUE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingMovieCard extends StatefulWidget {
  const _OnboardingMovieCard({
    required this.movie,
    required this.isLiked,
    required this.onTap,
  });

  final MovieModel movie;
  final bool isLiked;
  final VoidCallback onTap;

  @override
  State<_OnboardingMovieCard> createState() => _OnboardingMovieCardState();
}

class _OnboardingMovieCardState extends State<_OnboardingMovieCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isLiked ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: widget.isLiked
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Poster or gradient
                MoviePoster(
                  url: widget.movie.posterUrl,
                  blurHash: widget.movie.blurHash,
                  width: double.infinity,
                  height: double.infinity,
                  fallbackBuilder: (_) => _buildGradient(),
                ),
                // Bottom overlay with title
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.movie.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.movie.genres.isNotEmpty)
                          Text(
                            widget.movie.genres.first,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Liked check overlay
                if (widget.isLiked)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 18),
                    ),
                  ),
                // Hover overlay
                if (_hovering && !widget.isLiked)
                  Container(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.getGenreColor(
              widget.movie.genres.isNotEmpty ? widget.movie.genres.first : '',
            ).withValues(alpha: 0.8),
            AppColors.primaryDark.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Center(
        child: Text(
          widget.movie.title.isNotEmpty
              ? widget.movie.title[0].toUpperCase()
              : 'M',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
