import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_recommender_web/models/movie_model.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_notifier.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_state.dart';
import 'package:movie_recommender_web/notifiers/favorites/favorites_notifier.dart';
import 'package:movie_recommender_web/notifiers/favorites/favorites_state.dart';
import 'package:movie_recommender_web/theme/app_color.dart';
import 'package:movie_recommender_web/widgets/movie_card.dart';
import 'package:movie_recommender_web/widgets/state_widgets.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  int _selectedTab = 0;
  static const List<String> _tabs = ['All', 'By Genre', 'By Rating'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final AuthState authState = ref.read(authNotifierProvider);
      if (authState.isAuthenticated && authState.user != null) {
        ref.read(favoritesNotifierProvider.notifier).loadFavorites(authState.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final FavoritesState favState = ref.watch(favoritesNotifierProvider);
    final AuthState authState = ref.watch(authNotifierProvider);
    final int? userId = authState.user?.id;
    final List<MovieModel> filtered = _getFilteredFavorites(favState.favorites);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Favourites',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  if (favState.favorites.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${favState.favorites.length}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (favState.favorites.isNotEmpty)
                    _ClearAllButton(
                      onTap: () => _showClearConfirmation(context, userId),
                    ),
                ],
              ),
            ),
          ),

          // Sort tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 20),
              child: Row(
                children: List.generate(_tabs.length, (int index) {
                  final bool isActive = _selectedTab == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _SortChip(
                      label: _tabs[index],
                      isActive: isActive,
                      onTap: () => setState(() => _selectedTab = index),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Content
          if (favState.isLoading)
            const SliverLoadingView(message: 'Loading favourites...')
          else if (favState.errorMessage != null)
            SliverEmptyView(
              icon: Icons.error_outline,
              title: 'Failed to load favourites',
              message: favState.errorMessage!,
              actionLabel: 'Retry',
              onAction: () {
                if (userId != null) {
                  ref.read(favoritesNotifierProvider.notifier).loadFavorites(userId);
                }
              },
            )
          else if (favState.favorites.isEmpty)
            SliverEmptyView(
              icon: Icons.favorite_border_rounded,
              title: 'No favourites yet',
              message: 'Movies you favourite will appear here',
              actionLabel: 'Browse Movies',
              onAction: () => context.go('/search'),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  childAspectRatio: 0.48,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 24,
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final MovieModel movie = filtered[index];
                    return _FavoriteMovieCard(
                      movie: movie,
                      onTap: () => context.push('/movie/${movie.movieId}'),
                      onRemove: () {
                        if (userId != null) {
                          ref.read(favoritesNotifierProvider.notifier).removeFavorite(movie.movieId, userId);
                        }
                      },
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, int? userId) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Clear all favourites?', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: const Text(
            'This will remove all movies from your favourites list.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                if (userId != null) {
                  ref.read(favoritesNotifierProvider.notifier).clearAll(userId);
                }
              },
              child: const Text('Clear All', style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }

  List<MovieModel> _getFilteredFavorites(List<MovieModel> favorites) {
    switch (_selectedTab) {
      case 1:
        final List<MovieModel> sorted = List<MovieModel>.from(favorites);
        sorted.sort((MovieModel a, MovieModel b) {
          final String genreA = a.genres.isNotEmpty ? a.genres.first : '';
          final String genreB = b.genres.isNotEmpty ? b.genres.first : '';
          return genreA.compareTo(genreB);
        });
        return sorted;
      case 2:
        final List<MovieModel> sorted = List<MovieModel>.from(favorites);
        sorted.sort((MovieModel a, MovieModel b) => b.avgRating.compareTo(a.avgRating));
        return sorted;
      default:
        return favorites;
    }
  }
}

class _SortChip extends StatefulWidget {
  const _SortChip({required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_SortChip> createState() => _SortChipState();
}

class _SortChipState extends State<_SortChip> {
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
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.primary
                : _hovering
                    ? const Color(0xFF1E1E1E)
                    : const Color(0xFF141414),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isActive
                  ? AppColors.primary
                  : _hovering
                      ? const Color(0xFF3A3A3A)
                      : const Color(0xFF252525),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClearAllButton extends StatefulWidget {
  const _ClearAllButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_ClearAllButton> createState() => _ClearAllButtonState();
}

class _ClearAllButtonState extends State<_ClearAllButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          'Clear All',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _hovering ? AppColors.error : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FavoriteMovieCard extends StatefulWidget {
  const _FavoriteMovieCard({required this.movie, required this.onTap, required this.onRemove});
  final MovieModel movie;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  State<_FavoriteMovieCard> createState() => _FavoriteMovieCardState();
}

class _FavoriteMovieCardState extends State<_FavoriteMovieCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: widget.onTap,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return Stack(
                    children: [
                      MovieCard(
                        movie: widget.movie,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        showTitle: false,
                        showSubtitle: false,
                      ),
                      // Remove button on hover
                      if (_hovering)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: widget.onRemove,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      // Favorite badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            widget.movie.genres.isNotEmpty ? widget.movie.genres.first : '',
            maxLines: 1,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
