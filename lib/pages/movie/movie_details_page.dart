import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_recommender_web/models/movie_model.dart';
import 'package:movie_recommender_web/models/rating_model.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_notifier.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_state.dart';
import 'package:movie_recommender_web/notifiers/favorites/favorites_notifier.dart';
import 'package:movie_recommender_web/notifiers/favorites/favorites_state.dart';
import 'package:movie_recommender_web/notifiers/movie/movie_notifier.dart';
import 'package:movie_recommender_web/notifiers/movie/movie_state.dart';
import 'package:movie_recommender_web/services/service_providers.dart';
import 'package:movie_recommender_web/services/toast_service.dart';
import 'package:movie_recommender_web/theme/app_color.dart';
import 'package:movie_recommender_web/widgets/circle_button.dart';
import 'package:movie_recommender_web/widgets/movie_card.dart';
import 'package:movie_recommender_web/widgets/movie_poster.dart';
import 'package:movie_recommender_web/widgets/review_tile.dart';
import 'package:movie_recommender_web/widgets/state_widgets.dart';
import 'package:movie_recommender_web/widgets/trailer_dialog.dart';

class MovieDetailsPage extends ConsumerStatefulWidget {
  const MovieDetailsPage({required this.movieId, super.key});

  final String movieId;

  @override
  ConsumerState<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends ConsumerState<MovieDetailsPage> {
  static const int _kReviewPreviewLimit = 5;

  bool? _liked;
  int _selectedStars = 0;
  bool _submittingRating = false;
  bool _editingRating = false;
  bool _overviewExpanded = false;
  final TextEditingController _commentController = TextEditingController();
  MovieModel? _fetchedMovie;
  bool _isFetching = false;
  String? _refreshedFor;
  List<MovieModel> _similar = <MovieModel>[];
  bool _loadingSimilar = false;
  String? _similarError;
  int? _similarLoadedFor;
  List<MovieReviewModel> _reviews = <MovieReviewModel>[];
  int _totalReviews = 0;
  bool _loadingReviews = false;
  int? _reviewsLoadedFor;
  RatingModel? _myRating;
  bool _loadingMyRating = false;
  int? _myRatingLoadedFor;

  @override
  void initState() {
    super.initState();
    _scheduleInitialLoads();
  }

  @override
  void didUpdateWidget(covariant MovieDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movieId != widget.movieId) {
      // Route reused the same widget for a different movie → reset per-movie
      // caches and kick off fresh loads.
      _fetchedMovie = null;
      _refreshedFor = null;
      _similarLoadedFor = null;
      _reviewsLoadedFor = null;
      _myRatingLoadedFor = null;
      _similar = <MovieModel>[];
      _reviews = <MovieReviewModel>[];
      _myRating = null;
      _selectedStars = 0;
      _commentController.clear();
      _overviewExpanded = false;
      _scheduleInitialLoads();
    }
  }

  void _scheduleInitialLoads() {
    // Defer fetches until AFTER the first frame paints so route-transition
    // animations stay smooth. setState() from these loads then arrives on a
    // later frame instead of mid-animation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchMovieFromBackend();
      final int? userId = ref.read(authNotifierProvider).user?.id;
      final int? idInt = int.tryParse(widget.movieId);
      if (idInt != null) {
        _loadReviews(idInt);
        if (userId != null) {
          _loadSimilar(idInt, userId);
          _loadMyRating(idInt, userId);
        }
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  MovieModel? _findMovie(MovieState state) {
    final String id = widget.movieId;
    // Always prefer the fresh backend fetch when we have it — local lists may
    // come from recommendation endpoints where `avgRating` is actually the
    // predicted rating and `totalRatings` / `releaseYear` are zero/null.
    if (_fetchedMovie != null && _fetchedMovie!.movieId == id) {
      return _fetchedMovie;
    }
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
    return null;
  }

  Future<void> _fetchMovieFromBackend() async {
    if (_isFetching) return;
    final String id = widget.movieId;
    if (_refreshedFor == id) return;
    _isFetching = true;
    _refreshedFor = id;
    final result = await ref
        .read(movieServiceProvider)
        .getById(int.tryParse(id) ?? 0);
    result.when(
      success: (movie) {
        if (movie != null && mounted) {
          setState(() => _fetchedMovie = movie);
        }
      },
      failure: (_) {
        // Allow a retry on next build if it failed.
        _refreshedFor = null;
      },
    );
    _isFetching = false;
  }

  Future<void> _loadReviews(int movieId, {bool force = false}) async {
    if (_loadingReviews) return;
    if (!force && _reviewsLoadedFor == movieId) return;
    setState(() {
      _loadingReviews = true;
      _reviewsLoadedFor = movieId;
    });
    final result = await ref
        .read(ratingServiceProvider)
        .reviewsForMovie(movieId, limit: 1000);
    if (!mounted) return;
    result.when(
      success: (List<MovieReviewModel> list) {
        setState(() {
          _reviews = list;
          _totalReviews = list.length;
          _loadingReviews = false;
        });
      },
      failure: (_) {
        setState(() {
          _reviews = <MovieReviewModel>[];
          _totalReviews = 0;
          _loadingReviews = false;
          _reviewsLoadedFor = null;
        });
      },
    );
  }

  Future<void> _loadMyRating(
    int movieId,
    int userId, {
    bool force = false,
  }) async {
    if (_loadingMyRating) return;
    if (!force && _myRatingLoadedFor == movieId) return;
    _loadingMyRating = true;
    _myRatingLoadedFor = movieId;
    final result = await ref
        .read(ratingServiceProvider)
        .myRating(userId, movieId);
    if (!mounted) {
      _loadingMyRating = false;
      return;
    }
    result.when(
      success: (RatingModel? r) {
        setState(() {
          _myRating = r;
          _loadingMyRating = false;
          if (r != null) {
            _selectedStars = r.rating.round();
            _commentController.text = r.comment ?? '';
            _editingRating = false;
          }
        });
      },
      failure: (_) {
        _loadingMyRating = false;
        _myRatingLoadedFor = null;
      },
    );
  }

  Future<void> _loadSimilar(int movieId, int userId) async {
    if (_loadingSimilar || _similarLoadedFor == movieId) return;
    setState(() {
      _loadingSimilar = true;
      _similarError = null;
      _similarLoadedFor = movieId;
    });
    final result = await ref
        .read(recommendationServiceProvider)
        .similar(userId, movieId, n: 12);
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
      // Initial frames after navigation: show a skeleton instead of jumping
      // from "Movie not found" → real content. Real "not found" only fires
      // when the backend fetch has finished and returned no movie.
      final bool stillLoading = _isFetching || _refreshedFor == null;
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        body: stillLoading
            ? _MovieDetailsSkeleton(isWide: isWide)
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

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Background poster blur — wrapped in RepaintBoundary so it doesn't
          // get re-rasterised every frame during the route transition or when
          // the scroll view scrolls.
          if (movie.posterUrl != null && movie.posterUrl!.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 500,
              child: RepaintBoundary(
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
                      // Decode at ~500px tall — the backdrop is never larger,
                      // and full-size decode at 1000+ stalled first-frame paint.
                      memCacheHeight: 500,
                      maxHeightDiskCache: 500,
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
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
                                onTap: () => context.canPop()
                                    ? context.pop()
                                    : context.go('/home'),
                              ),
                              const Spacer(),
                              CircleButton(
                                icon: isFav
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFav ? AppColors.error : Colors.white,
                                onTap: () {
                                  if (userId != null) {
                                    ref
                                        .read(
                                          favoritesNotifierProvider.notifier,
                                        )
                                        .toggleFavorite(movie, userId);
                                  }
                                  ToastService.instance.show(
                                    context: context,
                                    title: isFav
                                        ? 'Removed from favorites'
                                        : 'Added to favorites',
                                    toastType: isFav
                                        ? ToastType.info
                                        : ToastType.success,
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

                      const SizedBox(height: 48),

                      // User reviews
                      _buildReviewsSection(movie, userId),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
              const Icon(
                Icons.star_rounded,
                color: AppColors.ratingFilled,
                size: 22,
              ),
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
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
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
        const SizedBox(height: 28),

        // Overview / synopsis
        if ((movie.overview ?? '').trim().isNotEmpty) ...[
          _buildOverviewBlock(movie.overview!.trim()),
          const SizedBox(height: 28),
        ],

        // Action buttons
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _ActionButton(
              icon: Icons.play_arrow_rounded,
              label: 'Watch Trailer',
              isActive: false,
              activeColor: AppColors.primary,
              onTap: () => TrailerDialog.show(
                context,
                movieId: movie.id,
                movieTitle: movie.title,
              ),
            ),
            _ActionButton(
              icon: _liked == true ? Icons.thumb_up : Icons.thumb_up_outlined,
              label: 'Like',
              isActive: _liked == true,
              activeColor: AppColors.success500,
              onTap: () async {
                setState(() => _liked = true);
                if (userId != null) {
                  final result = await ref
                      .read(feedbackServiceProvider)
                      .submit(
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
            _ActionButton(
              icon: _liked == false
                  ? Icons.thumb_down
                  : Icons.thumb_down_outlined,
              label: 'Dislike',
              isActive: _liked == false,
              activeColor: AppColors.error,
              onTap: () async {
                setState(() => _liked = false);
                if (userId != null) {
                  final result = await ref
                      .read(feedbackServiceProvider)
                      .submit(
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

  Widget _buildOverviewBlock(String overview) {
    const int collapsedLimit = 240;
    final bool isLong = overview.length > collapsedLimit;
    final bool showFull = _overviewExpanded || !isLong;
    final String shown = showFull
        ? overview
        : '${overview.substring(0, collapsedLimit).trimRight()}…';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OVERVIEW',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topLeft,
          child: Text(
            shown,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.55,
            ),
          ),
        ),
        if (isLong) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _overviewExpanded = !_overviewExpanded),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Text(
                _overviewExpanded ? 'Read less' : 'Read more',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRatingSection(MovieModel movie, int? userId) {
    // Show the "Your Rating" summary card when the user has already rated
    // this movie and is not currently editing.
    if (_myRating != null && !_editingRating) {
      return _buildYourRatingCard(_myRating!);
    }
    return _buildRatingForm(movie, userId);
  }

  Widget _buildYourRatingCard(RatingModel r) {
    final int stars = r.rating.round();
    final bool hasComment = (r.comment ?? '').trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Rating',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You rated this $stars / 5',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _submittingRating
                    ? null
                    : () {
                        setState(() {
                          _editingRating = true;
                          _selectedStars = stars;
                          _commentController.text = r.comment ?? '';
                        });
                      },
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (int i = 1; i <= 5; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    i <= stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i <= stars
                        ? AppColors.ratingFilled
                        : AppColors.grey400,
                    size: 28,
                  ),
                ),
            ],
          ),
          if (hasComment) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: Text(
                r.comment!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingForm(MovieModel movie, int? userId) {
    final bool isEdit = _myRating != null;
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
          const Icon(
            Icons.star_rounded,
            color: AppColors.ratingFilled,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            isEdit ? 'Edit Your Rating' : 'Rate this Movie',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your rating helps improve recommendations for everyone.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (int index) {
              final bool filled = index < _selectedStars;
              return GestureDetector(
                onTap: () => setState(() => _selectedStars = index + 1),
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
          if (_selectedStars > 0) ...[
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
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: TextField(
                controller: _commentController,
                enabled: !_submittingRating,
                minLines: 3,
                maxLines: 5,
                maxLength: 1000,
                cursorColor: AppColors.primary,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: 'Write a short review (optional)',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  counterStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isEdit)
                  TextButton(
                    onPressed: _submittingRating
                        ? null
                        : () {
                            setState(() {
                              _editingRating = false;
                              _selectedStars = _myRating!.rating.round();
                              _commentController.text =
                                  _myRating!.comment ?? '';
                            });
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                if (isEdit) const SizedBox(width: 12),
                SizedBox(
                  width: 220,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _submittingRating
                        ? null
                        : () => _submitRating(movie, userId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _submittingRating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            isEdit ? 'Save Changes' : 'Submit Rating',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submitRating(MovieModel movie, int? userId) async {
    if (userId == null || _selectedStars == 0 || _submittingRating) return;
    setState(() => _submittingRating = true);
    final String trimmed = _commentController.text.trim();
    final result = await ref
        .read(ratingServiceProvider)
        .submit(
          userId: userId,
          movieId: movie.id,
          rating: _selectedStars.toDouble(),
          comment: trimmed.isEmpty ? null : trimmed,
        );
    if (!mounted) return;
    result.when(
      success: (_) {
        setState(() {
          _submittingRating = false;
          _editingRating = false;
        });
        ToastService.instance.show(
          context: context,
          title: trimmed.isEmpty
              ? 'Rating submitted! ($_selectedStars stars)'
              : 'Rating + review submitted!',
          toastType: ToastType.success,
        );
        // Refresh recommendations + movie totals + reviews + my-rating so the
        // UI matches the new persisted state.
        ref
            .read(movieNotifierProvider.notifier)
            .loadRecommendations(userId, algorithm: 'user_user');
        _refreshedFor = null;
        _fetchMovieFromBackend();
        _loadReviews(movie.id, force: true);
        _loadMyRating(movie.id, userId, force: true);
      },
      failure: (_) {
        setState(() => _submittingRating = false);
        ToastService.instance.show(
          context: context,
          title: 'Failed to submit rating',
          toastType: ToastType.error,
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _buildEmptyPlaceholder({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarSection() {
    Widget body;
    if (_loadingSimilar && _similar.isEmpty) {
      body = const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_similar.isEmpty) {
      body = _buildEmptyPlaceholder(
        icon: Icons.movie_outlined,
        title: 'No similar movies yet',
        message: _similarError != null
            ? 'Could not load similar movies right now. Try again later.'
            : 'Rate a few more movies and we will surface ones like this here.',
      );
    } else {
      body = SizedBox(
        height: 280,
        child: ListView.separated(
          cacheExtent: 600,
          scrollDirection: Axis.horizontal,
          itemCount: _similar.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (BuildContext context, int index) {
            final MovieModel m = _similar[index];
            return MovieCard(
              movie: m,
              width: 140,
              height: 210,
              onTap: () => context.go('/movie/${m.movieId}'),
            );
          },
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionHeader('Similar Movies'),
        const SizedBox(height: 16),
        body,
      ],
    );
  }

  Widget _buildReviewsSection(MovieModel movie, int? userId) {
    Widget body;
    if (_loadingReviews && _reviews.isEmpty) {
      body = const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_reviews.isEmpty) {
      body = _buildEmptyPlaceholder(
        icon: Icons.rate_review_outlined,
        title: 'No reviews yet',
        message: 'Be the first to write a review for this movie.',
      );
    } else {
      final List<MovieReviewModel> preview = _reviews
          .take(_kReviewPreviewLimit)
          .toList();
      body = Column(
        children: [
          for (int i = 0; i < preview.length; i++) ...[
            ReviewTile(
              review: preview[i],
              isMine: userId != null && preview[i].userId == userId,
            ),
            if (i != preview.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    final bool hasMore = _totalReviews > _kReviewPreviewLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: [
            _buildSectionHeader('User Reviews'),
            const SizedBox(width: 10),
            if (_totalReviews > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$_totalReviews',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        body,
        if (hasMore) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/movie/${movie.movieId}/reviews'),
              icon: const Icon(Icons.forum_outlined, size: 18),
              label: Text('See all $_totalReviews reviews'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MovieDetailsSkeleton extends StatelessWidget {
  const _MovieDetailsSkeleton({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final double posterW = isWide ? 320 : 240;
    final double posterH = isWide ? 480 : 360;
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isWide ? 48 : 24,
              24,
              isWide ? 48 : 24,
              48,
            ),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(width: posterW, height: posterH, radius: 12),
                      const SizedBox(width: 48),
                      Expanded(child: _buildInfoSkeleton()),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: _SkeletonBox(
                          width: posterW,
                          height: posterH,
                          radius: 12,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildInfoSkeleton(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SkeletonBox(width: 280, height: 36, radius: 6),
        SizedBox(height: 16),
        _SkeletonBox(width: 160, height: 20, radius: 4),
        SizedBox(height: 24),
        Row(
          children: [
            _SkeletonBox(width: 70, height: 28, radius: 14),
            SizedBox(width: 8),
            _SkeletonBox(width: 70, height: 28, radius: 14),
            SizedBox(width: 8),
            _SkeletonBox(width: 70, height: 28, radius: 14),
          ],
        ),
        SizedBox(height: 28),
        _SkeletonBox(width: 80, height: 12, radius: 4),
        SizedBox(height: 10),
        _SkeletonBox(width: double.infinity, height: 14, radius: 4),
        SizedBox(height: 8),
        _SkeletonBox(width: double.infinity, height: 14, radius: 4),
        SizedBox(height: 8),
        _SkeletonBox(width: 240, height: 14, radius: 4),
        SizedBox(height: 28),
        Row(
          children: [
            _SkeletonBox(width: 140, height: 44, radius: 22),
            SizedBox(width: 12),
            _SkeletonBox(width: 100, height: 44, radius: 22),
            SizedBox(width: 12),
            _SkeletonBox(width: 100, height: 44, radius: 22),
          ],
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    // Static fill — the skeleton only shows for a single frame or two while
    // the post-frame load completes, so a shimmer ticker would burn vsync
    // callbacks for no perceptible benefit (and previously caused frame drops
    // during the route transition).
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(radius),
      ),
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
    final Color fg = widget.isActive
        ? widget.activeColor
        : AppColors.textSecondary;
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
