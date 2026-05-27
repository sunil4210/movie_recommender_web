import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_recommender_web/models/movie_model.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_notifier.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_state.dart';
import 'package:movie_recommender_web/notifiers/favorites/favorites_notifier.dart';
import 'package:movie_recommender_web/notifiers/favorites/favorites_state.dart';
import 'package:movie_recommender_web/notifiers/movie/movie_notifier.dart';
import 'package:movie_recommender_web/notifiers/movie/movie_state.dart';
import 'package:movie_recommender_web/services/toast_service.dart';
import 'package:movie_recommender_web/theme/app_color.dart';
import 'package:movie_recommender_web/widgets/circle_button.dart';
import 'package:movie_recommender_web/widgets/movie_card.dart';
import 'package:movie_recommender_web/widgets/movie_poster.dart';
import 'package:movie_recommender_web/widgets/state_widgets.dart';

class MovieDetailsPage extends ConsumerStatefulWidget {
  const MovieDetailsPage({required this.movieId, super.key});

  final String movieId;

  @override
  ConsumerState<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends ConsumerState<MovieDetailsPage> {
  bool? _liked;
  int _selectedStars = 0;
  bool _ratingSubmitted = false;
  MovieModel? _fetchedMovie;
  bool _isFetching = false;
  List<MovieModel> _similar = <MovieModel>[];
  bool _loadingSimilar = false;
  String? _similarError;
  int? _similarLoadedFor;

  MovieModel? _findMovie(MovieState state) {
    // Search all available movie lists
    final String id = widget.movieId;
    final List<List<MovieModel>> lists = [
      state.allMovies,
      state.recommendations,
      state.popularMovies,
      state.trendingMovies,
      state.newArrivals,
      state.searchResults,
    ];
    for (final List<MovieModel> list in lists) {
      try {
        return list.firstWhere((MovieModel m) => m.movieId == id);
      } catch (_) {
        continue;
      }
    }
    return _fetchedMovie;
  }

  Future<void> _fetchMovieFromBackend() async {
    if (_isFetching) return;
    _isFetching = true;
    final result = await ref
        .read(databaseServiceProvider)
        .getMovie(int.tryParse(widget.movieId) ?? 0);
    result.when(
      success: (movie) {
        if (movie != null && mounted) {
          setState(() => _fetchedMovie = movie);
        }
      },
      failure: (_) {},
    );
    _isFetching = false;
  }

  Future<void> _loadSimilar(int movieId, int userId) async {
    if (_loadingSimilar || _similarLoadedFor == movieId) return;
    setState(() {
      _loadingSimilar = true;
      _similarError = null;
      _similarLoadedFor = movieId;
    });
    final result = await ref
        .read(databaseServiceProvider)
        .getSimilarMovies(userId, movieId, n: 12);
    if (!mounted) return;
    result.when(
      success: (List<MovieModel> movies) {
        setState(() {
          _similar = movies.where((MovieModel m) => m.id != movieId).toList();
          _loadingSimilar = false;
        });
      },
      failure: (exception) {
        setState(() {
          _similar = <MovieModel>[];
          _similarError = exception.message;
          _loadingSimilar = false;
          _similarLoadedFor = null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final MovieState movieState = ref.watch(movieNotifierProvider);
    final FavoritesState favState = ref.watch(favoritesNotifierProvider);
    final AuthState authState = ref.watch(authNotifierProvider);
    final MovieModel? movie = _findMovie(movieState);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 900;

    if (movie == null) {
      // Try fetching from backend
      _fetchMovieFromBackend();
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        body: _isFetching
            ? const Center(child: CircularProgressIndicator())
            : AppErrorView(
                icon: Icons.movie_filter,
                title: 'Movie not found',
                message: 'This movie may have been removed or is unavailable.',
                onRetry: () => context.pop(),
              ),
      );
    }

    final bool isFav = favState.isFavorite(movie.movieId);
    final int? userId = authState.user?.id;

    if (userId != null && _similarLoadedFor != movie.id) {
      Future.microtask(() => _loadSimilar(movie.id, userId));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Background poster blur
          if (movie.posterUrl != null && movie.posterUrl!.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 500,
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.transparent],
                    stops: [0.3, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: Opacity(
                  opacity: 0.3,
                  child: CachedNetworkImage(
                    imageUrl: movie.posterUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

          // Main content
          SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 48 : 24,
                    0,
                    isWide ? 48 : 24,
                    48,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button row
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 24),
                          child: Row(
                            children: [
                              CircleButton(
                                icon: Icons.arrow_back,
                                onTap: () => context.pop(),
                              ),
                              const Spacer(),
                              CircleButton(
                                icon: isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? AppColors.error : Colors.white,
                                onTap: () {
                                  if (userId != null) {
                                    ref.read(favoritesNotifierProvider.notifier).toggleFavorite(movie, userId);
                                  }
                                  ToastService.instance.show(
                                    context: context,
                                    title: isFav ? 'Removed from favorites' : 'Added to favorites',
                                    toastType: isFav ? ToastType.info : ToastType.success,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Poster + Info layout
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPoster(movie, 320, 480),
                            const SizedBox(width: 48),
                            Expanded(child: _buildMovieInfo(movie, userId)),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(child: _buildPoster(movie, 240, 360)),
                            const SizedBox(height: 32),
                            _buildMovieInfo(movie, userId),
                          ],
                        ),

                      const SizedBox(height: 48),

                      // Rate this movie section
                      _buildRatingSection(movie, userId),

                      const SizedBox(height: 48),

                      // Similar movies rail
                      _buildSimilarSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoster(MovieModel movie, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: MoviePoster(
        url: movie.posterUrl,
        blurHash: movie.blurHash,
        width: width,
        height: height,
        fallbackBuilder: (_) => _buildPosterFallback(movie, height),
      ),
    );
  }

  Widget _buildPosterFallback(MovieModel movie, double height) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.getGenreColor(
              movie.genres.isNotEmpty ? movie.genres.first : '',
            ).withValues(alpha: 0.8),
            AppColors.primaryDark.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Center(
        child: Text(
          movie.title.isNotEmpty ? movie.title[0].toUpperCase() : 'M',
          style: TextStyle(
            fontSize: height * 0.25,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildMovieInfo(MovieModel movie, int? userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          movie.title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),

        // Year + Rating row
        Row(
          children: [
            if (movie.releaseYear != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.grey400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${movie.releaseYear}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            if (movie.avgRating > 0) ...[
              const Icon(Icons.star_rounded, color: AppColors.ratingFilled, size: 22),
              const SizedBox(width: 4),
              Text(
                movie.avgRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${movie.totalRatings} ratings)',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
        const SizedBox(height: 20),

        // Genre tags
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: movie.genres.map((String genre) {
            final Color color = AppColors.getGenreColor(genre);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Text(
                genre,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        // Action buttons
        Row(
          children: [
            _ActionButton(
              icon: _liked == true ? Icons.thumb_up : Icons.thumb_up_outlined,
              label: 'Like',
              isActive: _liked == true,
              activeColor: AppColors.success500,
              onTap: () async {
                setState(() => _liked = true);
                if (userId != null) {
                  final result = await ref.read(databaseServiceProvider).submitFeedback(
                        userId: userId,
                        movieId: movie.id,
                        feedbackType: 'thumbs_up',
                      );
                  result.when(
                    success: (_) => ToastService.instance.show(
                      context: context,
                      title: 'You liked this movie!',
                      toastType: ToastType.success,
                    ),
                    failure: (_) {
                      setState(() => _liked = null);
                      ToastService.instance.show(
                        context: context,
                        title: 'Failed to submit feedback',
                        toastType: ToastType.error,
                      );
                    },
                  );
                }
              },
            ),
            const SizedBox(width: 12),
            _ActionButton(
              icon: _liked == false ? Icons.thumb_down : Icons.thumb_down_outlined,
              label: 'Dislike',
              isActive: _liked == false,
              activeColor: AppColors.error,
              onTap: () async {
                setState(() => _liked = false);
                if (userId != null) {
                  final result = await ref.read(databaseServiceProvider).submitFeedback(
                        userId: userId,
                        movieId: movie.id,
                        feedbackType: 'thumbs_down',
                      );
                  result.when(
                    success: (_) => ToastService.instance.show(
                      context: context,
                      title: 'Thanks for your feedback!',
                      toastType: ToastType.info,
                    ),
                    failure: (_) {
                      setState(() => _liked = null);
                      ToastService.instance.show(
                        context: context,
                        title: 'Failed to submit feedback',
                        toastType: ToastType.error,
                      );
                    },
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingSection(MovieModel movie, int? userId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        children: [
          const Icon(Icons.star_rounded, color: AppColors.ratingFilled, size: 36),
          const SizedBox(height: 12),
          const Text(
            'Rate this Movie',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _ratingSubmitted
                ? 'Thanks for rating!'
                : 'Your rating helps improve recommendations for everyone.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          // Star row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (int index) {
              final bool filled = index < _selectedStars;
              return GestureDetector(
                onTap: _ratingSubmitted
                    ? null
                    : () {
                        setState(() => _selectedStars = index + 1);
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled ? AppColors.ratingFilled : AppColors.grey400,
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          if (_selectedStars > 0 && !_ratingSubmitted) ...[
            const SizedBox(height: 8),
            Text(
              '$_selectedStars / 5',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              height: 44,
              child: ElevatedButton(
                onPressed: () async {
                  if (userId != null && _selectedStars > 0) {
                    final result = await ref.read(databaseServiceProvider).submitRating(
                          userId: userId,
                          movieId: movie.id,
                          rating: _selectedStars.toDouble(),
                        );
                    result.when(
                      success: (_) {
                        setState(() => _ratingSubmitted = true);
                        ToastService.instance.show(
                          context: context,
                          title: 'Rating submitted! ($_selectedStars stars)',
                          toastType: ToastType.success,
                        );
                      },
                      failure: (_) {
                        ToastService.instance.show(
                          context: context,
                          title: 'Failed to submit rating',
                          toastType: ToastType.error,
                        );
                      },
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Submit Rating', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimilarSection() {
    if (_loadingSimilar && _similar.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_similarError != null && _similar.isEmpty) {
      return const SizedBox.shrink();
    }
    if (_similar.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Similar Movies',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _similar.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (BuildContext context, int index) {
              final MovieModel m = _similar[index];
              return MovieCard(
                movie: m,
                width: 140,
                height: 210,
                onTap: () => context.pushReplacement('/movie/${m.movieId}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final Color fg = widget.isActive ? widget.activeColor : AppColors.textSecondary;
    final Color bg = widget.isActive
        ? widget.activeColor.withValues(alpha: 0.12)
        : _hovering
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.transparent;
    final Color border = widget.isActive
        ? widget.activeColor.withValues(alpha: 0.3)
        : _hovering
            ? Colors.white.withValues(alpha: 0.15)
            : const Color(0xFF2A2A2A);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
