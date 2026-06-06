import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_recommender_web/models/movie_model.dart';
import 'package:movie_recommender_web/models/rating_model.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_notifier.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_state.dart';
import 'package:movie_recommender_web/services/service_providers.dart';
import 'package:movie_recommender_web/theme/app_color.dart';
import 'package:movie_recommender_web/widgets/circle_button.dart';
import 'package:movie_recommender_web/widgets/movie_poster.dart';
import 'package:movie_recommender_web/widgets/review_tile.dart';

enum ReviewSort { newest, oldest, highest, lowest }

extension on ReviewSort {
  String get apiValue {
    switch (this) {
      case ReviewSort.newest:
        return 'newest';
      case ReviewSort.oldest:
        return 'oldest';
      case ReviewSort.highest:
        return 'highest';
      case ReviewSort.lowest:
        return 'lowest';
    }
  }

  String get label {
    switch (this) {
      case ReviewSort.newest:
        return 'Newest first';
      case ReviewSort.oldest:
        return 'Oldest first';
      case ReviewSort.highest:
        return 'Highest rated';
      case ReviewSort.lowest:
        return 'Lowest rated';
    }
  }

  IconData get icon {
    switch (this) {
      case ReviewSort.newest:
        return Icons.schedule;
      case ReviewSort.oldest:
        return Icons.history;
      case ReviewSort.highest:
        return Icons.trending_up;
      case ReviewSort.lowest:
        return Icons.trending_down;
    }
  }
}

class MovieReviewsPage extends ConsumerStatefulWidget {
  const MovieReviewsPage({required this.movieId, super.key});

  final String movieId;

  @override
  ConsumerState<MovieReviewsPage> createState() => _MovieReviewsPageState();
}

class _MovieReviewsPageState extends ConsumerState<MovieReviewsPage> {
  ReviewSort _sort = ReviewSort.newest;
  List<MovieReviewModel> _reviews = <MovieReviewModel>[];
  bool _loading = false;
  bool _initialLoadDone = false;
  MovieModel? _movie;
  bool _fetchedMovie = false;

  @override
  void initState() {
    super.initState();
    // Defer both fetches until after first paint so route transition stays
    // smooth — setState() then arrives on a later frame instead of mid-anim.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
      _fetchMovie();
    });
  }

  Future<void> _fetchMovie() async {
    if (_fetchedMovie) return;
    _fetchedMovie = true;
    final int? idInt = int.tryParse(widget.movieId);
    if (idInt == null) return;
    final result =
        await ref.read(movieServiceProvider).getById(idInt);
    if (!mounted) return;
    result.when(
      success: (MovieModel? m) {
        if (m != null) setState(() => _movie = m);
      },
      failure: (_) {},
    );
  }

  Future<void> _load() async {
    if (_loading) return;
    final int? idInt = int.tryParse(widget.movieId);
    if (idInt == null) return;
    final int? pinUserId = ref.read(authNotifierProvider).user?.id;

    setState(() => _loading = true);
    final result = await ref.read(ratingServiceProvider).reviewsForMovie(
          idInt,
          limit: 1000,
          sort: _sort.apiValue,
          pinUserId: pinUserId,
        );
    if (!mounted) return;
    result.when(
      success: (List<MovieReviewModel> list) {
        setState(() {
          _reviews = list;
          _loading = false;
          _initialLoadDone = true;
        });
      },
      failure: (_) {
        setState(() {
          _reviews = <MovieReviewModel>[];
          _loading = false;
          _initialLoadDone = true;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = ref.watch(authNotifierProvider);
    final int? userId = authState.user?.id;
    final double width = MediaQuery.of(context).size.width;
    final bool isWide = width > 900;
    final MovieModel? movie = _movie;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Blurred backdrop poster — mirrors movie_details_page.
          if (movie != null &&
              movie.posterUrl != null &&
              movie.posterUrl!.isNotEmpty)
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
                      memCacheHeight: 500,
                      maxHeightDiskCache: 500,
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),

          // Main content — CustomScrollView so the (potentially long) reviews
          // list builds lazily via SliverList instead of eagerly via
          // shrinkWrap+ListView, which was the main jank source.
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      isWide ? 48 : 24,
                      0,
                      isWide ? 48 : 24,
                      24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate.fixed([
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 24),
                            child: CircleButton(
                              icon: Icons.arrow_back,
                              onTap: () => context.canPop()
                                  ? context.pop()
                                  : context.go('/movie/${widget.movieId}'),
                            ),
                          ),
                        ),
                        if (movie != null)
                          isWide
                              ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _buildPoster(movie, 220, 330),
                                    const SizedBox(width: 40),
                                    Expanded(
                                        child: _buildMovieSummary(movie)),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                        child:
                                            _buildPoster(movie, 180, 270)),
                                    const SizedBox(height: 24),
                                    _buildMovieSummary(movie),
                                  ],
                                )
                        else
                          const SizedBox(
                            height: 200,
                            child:
                                Center(child: CircularProgressIndicator()),
                          ),
                        const SizedBox(height: 40),
                        Container(
                          height: 1,
                          color: const Color(0xFF1A1A1A),
                        ),
                        const SizedBox(height: 24),
                        _buildReviewsHeader(),
                        const SizedBox(height: 20),
                      ]),
                    ),
                  ),
                  _buildReviewsSliver(userId, isWide),
                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                ],
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
        fallbackBuilder: (_) => Container(
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
        ),
      ),
    );
  }

  Widget _buildMovieSummary(MovieModel movie) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'REVIEWS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          movie.title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
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
              const Icon(Icons.star_rounded,
                  color: AppColors.ratingFilled, size: 22),
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
        const SizedBox(height: 16),
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
      ],
    );
  }

  Widget _buildReviewsHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.forum_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                _initialLoadDone ? '${_reviews.length} reviews' : '— reviews',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _buildSortDropdown(),
      ],
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ReviewSort>(
          value: _sort,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.textSecondary),
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          onChanged: (ReviewSort? v) {
            if (v == null || v == _sort) return;
            setState(() => _sort = v);
            _load();
          },
          items: ReviewSort.values
              .map(
                (ReviewSort s) => DropdownMenuItem<ReviewSort>(
                  value: s,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(s.icon, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(s.label),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildReviewsSliver(int? userId, bool isWide) {
    final EdgeInsets pad = EdgeInsets.symmetric(horizontal: isWide ? 48 : 24);
    if (_loading && _reviews.isEmpty) {
      return SliverPadding(
        padding: pad.add(const EdgeInsets.symmetric(vertical: 48)),
        sliver: const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_reviews.isEmpty) {
      return SliverPadding(
        padding: pad,
        sliver: SliverToBoxAdapter(
          child: _buildEmptyPlaceholder(
            icon: Icons.rate_review_outlined,
            title: 'No reviews yet',
            message: 'Be the first to write a review for this movie.',
          ),
        ),
      );
    }
    return SliverPadding(
      padding: pad,
      sliver: SliverList.separated(
        itemCount: _reviews.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final MovieReviewModel r = _reviews[index];
          // RepaintBoundary isolates per-tile repaints from scroll updates.
          return RepaintBoundary(
            child: ReviewTile(
              review: r,
              isMine: userId != null && r.userId == userId,
            ),
          );
        },
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
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
}
