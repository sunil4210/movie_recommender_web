import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_recommender_web/core/constants/movie_genres.dart';
import 'package:movie_recommender_web/core/router/app_router.dart';
import 'package:movie_recommender_web/models/movie_model.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_notifier.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_state.dart';
import 'package:movie_recommender_web/notifiers/movie/movie_notifier.dart';
import 'package:movie_recommender_web/notifiers/movie/movie_state.dart';
import 'package:movie_recommender_web/theme/app_color.dart';
import 'package:movie_recommender_web/widgets/genre_pill.dart';
import 'package:movie_recommender_web/widgets/movie_card.dart';
import 'package:movie_recommender_web/widgets/section_header.dart';
import 'package:movie_recommender_web/widgets/state_widgets.dart';
import 'package:movie_recommender_web/widgets/trailer_dialog.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// Cached random pick used for the hero banner so it doesn't flicker on rebuild.
  /// Reset to null on pull-to-refresh so the next build picks a fresh movie.
  MovieModel? _heroMovie;

  @override
  void initState() {
    super.initState();
    // Defer to next microtask so providers are ready before we read them.
    Future.microtask(() {
      final MovieState movieState = ref.read(movieNotifierProvider);
      if (movieState.status == MovieStatus.initial) {
        ref.read(movieNotifierProvider.notifier).loadMovies();
      }
      final AuthState authState = ref.read(authNotifierProvider);
      if (authState.isAuthenticated && authState.user != null) {
        // User-User CF is the only production algorithm.
        ref.read(movieNotifierProvider.notifier).loadRecommendations(authState.user!.id, algorithm: 'user_user');
      }
    });
  }

  /// Pick a random hero movie from recommendations, or fall back to popular
  MovieModel? _pickHeroMovie(MovieState movieState) {
    if (_heroMovie != null) return _heroMovie;

    final List<MovieModel> pool = movieState.recommendations.isNotEmpty
        ? movieState.recommendations
        : movieState.popularMovies;

    if (pool.isEmpty) return null;

    _heroMovie = pool[Random().nextInt(pool.length)];
    return _heroMovie;
  }

  @override
  Widget build(BuildContext context) {
    final MovieState movieState = ref.watch(movieNotifierProvider);
    final AuthState authState = ref.watch(authNotifierProvider);

    // Load recommendations when auth becomes available (handles late auth)
    ref.listen<AuthState>(authNotifierProvider, (AuthState? prev, AuthState next) {
      if (next.isAuthenticated && next.user != null && !(prev?.isAuthenticated ?? false)) {
        ref.read(movieNotifierProvider.notifier).loadRecommendations(next.user!.id, algorithm: 'user_user');
      }
    });
    final double screenWidth = MediaQuery.of(context).size.width;

    // Responsive card sizing
    final double cardWidth = screenWidth > 1200 ? 180 : (screenWidth > 800 ? 160 : 140);
    final double cardHeight = cardWidth * 1.5;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: movieState.status == MovieStatus.loading
          ? const AppLoadingView(message: 'Loading movies...')
          : movieState.status == MovieStatus.error
              ? AppErrorView(
                  title: 'Failed to load movies',
                  message: movieState.errorMessage,
                  onRetry: () => ref.read(movieNotifierProvider.notifier).loadMovies(),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _heroMovie = null;
                    await ref.read(movieNotifierProvider.notifier).loadMovies();
                    if (authState.isAuthenticated && authState.user != null) {
                      await ref
                          .read(movieNotifierProvider.notifier)
                          .loadRecommendations(authState.user!.id, algorithm: 'user_user');
                    }
                  },
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Hero Section — random recommendation
                      _buildHeroSection(movieState, authState),

                      const SizedBox(height: 48),

                      // Recommended for You
                      if (movieState.recommendations.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Recommended for You',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildHorizontalMovieList(
                          movies: movieState.recommendations,
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                        ),
                        const SizedBox(height: 48),
                      ],

                      // Top Rated Movies (highest average rating with min 20 ratings)
                      const SectionHeader(title: 'Top Rated Movies'),
                      const SizedBox(height: 16),
                      _buildHorizontalMovieList(
                        movies: movieState.popularMovies,
                        cardWidth: cardWidth,
                        cardHeight: cardHeight,
                      ),
                      const SizedBox(height: 48),

                      // Browse by Genre
                      _buildGenreChips(),
                      const SizedBox(height: 48),

                      // Trending Now (most recent rating activity)
                      if (movieState.trendingMovies.isNotEmpty) ...[
                        const SectionHeader(title: 'Trending Now'),
                        const SizedBox(height: 16),
                        _buildHorizontalMovieList(
                          movies: movieState.trendingMovies,
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                        ),
                        const SizedBox(height: 48),
                      ],

                      // Footer
                      _buildFooter(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeroSection(MovieState movieState, AuthState authState) {
    final MovieModel? heroMovie = _pickHeroMovie(movieState);

    return Container(
      height: 480,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.6, 1.0],
          colors: [
            if (heroMovie != null)
              AppColors.getGenreColor(
                heroMovie.genres.isNotEmpty ? heroMovie.genres.first : '',
              ).withValues(alpha: 0.35)
            else
              AppColors.primary.withValues(alpha: 0.25),
            const Color(0xFF0A0A0A).withValues(alpha: 0.8),
            const Color(0xFF0A0A0A),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background poster image (blurred/faded)
          if (heroMovie?.posterUrl != null && heroMovie!.posterUrl!.isNotEmpty)
            Positioned.fill(
              child: Opacity(
                opacity: 0.25,
                child: CachedNetworkImage(
                  imageUrl: heroMovie.posterUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          // Left-to-right gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF0A0A0A).withValues(alpha: 0.95),
                  const Color(0xFF0A0A0A).withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Bottom fade
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 160,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFF0A0A0A)],
                ),
              ),
            ),
          ),
          // Hero content
          Positioned(
            left: 32,
            bottom: 60,
            right: MediaQuery.of(context).size.width * 0.4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (authState.isAuthenticated && authState.user != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      '${_timeBasedGreeting()}, ${authState.user!.firstName ?? authState.user!.displayName}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                if (heroMovie != null) ...[
                  Text(
                    heroMovie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Meta row
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    children: [
                      if (heroMovie.avgRating > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: AppColors.ratingFilled, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              heroMovie.avgRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      if (heroMovie.avgRating > 0)
                        _dot(),
                      Text(
                        heroMovie.genres.take(3).join(', '),
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      if (heroMovie.releaseYear != null) ...[
                        _dot(),
                        Text(
                          '${heroMovie.releaseYear}',
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _HeroButton(
                        icon: Icons.play_arrow_rounded,
                        label: 'WATCH TRAILER',
                        onTap: () => TrailerDialog.show(
                          context,
                          movieId: heroMovie.id,
                          movieTitle: heroMovie.title,
                        ),
                        primary: true,
                      ),
                      _HeroButton(
                        icon: Icons.info_outline,
                        label: 'MORE INFO',
                        onTap: () => context.go('/movie/${heroMovie.movieId}'),
                        primary: false,
                      ),
                      _HeroButton(
                        icon: Icons.add,
                        label: 'MY LIST',
                        onTap: () => context.go(AppRoutes.favorites),
                        primary: false,
                      ),
                    ],
                  ),
                ] else
                  const Text(
                    'Discover your next\nfavorite movie',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Time-of-day greeting shown above the hero section.
  /// Buckets: 00:00-11:59 morning, 12:00-16:59 afternoon, 17:00-23:59 evening.
  String _timeBasedGreeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _dot() {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: AppColors.textSecondary,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildHorizontalMovieList({
    required List<MovieModel> movies,
    double cardWidth = 160,
    double cardHeight = 240,
  }) {
    if (movies.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No movies available',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return SizedBox(
      height: cardHeight + 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        itemCount: movies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (BuildContext context, int index) {
          final MovieModel movie = movies[index];
          return MovieCard(
            movie: movie,
            width: cardWidth,
            height: cardHeight,
            onTap: () => context.go('/movie/${movie.movieId}'),
          );
        },
      ),
    );
  }

  Widget _buildGenreChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Browse by Genre',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kMovieGenres.map((GenreItem genre) {
              return GenrePill(
                label: genre.label,
                icon: genre.icon,
                isSelected: false,
                onTap: () {
                  ref.read(movieNotifierProvider.notifier).filterByGenre(genre.label);
                  context.go('/search');
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A2A), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Footer links
          Wrap(
            spacing: 24,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: const [
              _FooterLink(label: 'About'),
              _FooterLink(label: 'Help Center'),
              _FooterLink(label: 'Privacy'),
              _FooterLink(label: 'Terms of Service'),
              _FooterLink(label: 'Contact'),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            '© 2025 CineMatch. All rights reserved.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatefulWidget {
  const _HeroButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.primary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final Color baseBg = widget.primary
        ? AppColors.primary
        : Colors.white.withValues(alpha: 0.12);
    final Color hoverBg = widget.primary
        ? AppColors.primary.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.22);
    final Color border = widget.primary
        ? AppColors.primary
        : Colors.white.withValues(alpha: 0.3);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: _hovering ? hoverBg : baseBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
