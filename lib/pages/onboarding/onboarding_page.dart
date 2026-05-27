import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_recommender_web/core/router/app_router.dart';
import 'package:movie_recommender_web/models/movie_model.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_notifier.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_state.dart';
import 'package:movie_recommender_web/notifiers/movie/movie_notifier.dart';
import 'package:movie_recommender_web/notifiers/movie/movie_state.dart';
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

  static const int _minLikes = 5;

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
    final db = ref.read(databaseServiceProvider);

    // Submit ratings for all liked movies (5.0 = liked)
    for (final int movieId in _likedMovieIds) {
      await db.submitRating(userId: userId, movieId: movieId, rating: 5.0);
    }

    // Load recommendations with new ratings
    await ref.read(movieNotifierProvider.notifier).loadRecommendations(userId);

    if (mounted) {
      ToastService.instance.show(
        context: context,
        title: 'Great picks! Here are your recommendations',
        toastType: ToastType.success,
      );
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MovieState movieState = ref.watch(movieNotifierProvider);
    final int remaining = _minLikes - _likedMovieIds.length;

    // Use popular + trending as onboarding pool
    final List<MovieModel> moviePool = [
      ...movieState.popularMovies,
      ...movieState.trendingMovies,
    ];

    // Deduplicate
    final Set<int> seen = {};
    final List<MovieModel> movies = moviePool.where((MovieModel m) {
      if (seen.contains(m.id)) return false;
      seen.add(m.id);
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
            child: Column(
              children: [
                const Text(
                  'What movies do you like?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  remaining > 0
                      ? 'Pick at least $_minLikes movies to get personalized recommendations. $remaining more to go.'
                      : 'Looking good! You can keep adding or continue.',
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
                // Skip button
                TextButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
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
