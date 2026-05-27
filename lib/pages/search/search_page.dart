import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:movie_recommender_web/core/constants/movie_genres.dart';
import 'package:movie_recommender_web/models/movie_model.dart';
import 'package:movie_recommender_web/notifiers/movie/movie_notifier.dart';
import 'package:movie_recommender_web/notifiers/movie/movie_state.dart';
import 'package:movie_recommender_web/theme/app_color.dart';
import 'package:movie_recommender_web/widgets/genre_pill.dart';
import 'package:movie_recommender_web/widgets/movie_card.dart';
import 'package:movie_recommender_web/widgets/state_widgets.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final MovieState movieState = ref.read(movieNotifierProvider);
      if (movieState.status == MovieStatus.initial) {
        ref.read(movieNotifierProvider.notifier).loadMovies();
      }
      if (movieState.searchQuery.isNotEmpty &&
          _searchController.text != movieState.searchQuery) {
        _searchController.text = movieState.searchQuery;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MovieState movieState = ref.watch(movieNotifierProvider);
    final String? selectedGenre = movieState.selectedGenre;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 768;
    final bool hasQuery = _searchController.text.isNotEmpty || selectedGenre != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        slivers: [
          // ── Header: Title row + Search + Genres ──
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Search row
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Movies',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 320,
                          child: _SearchBar(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            onChanged: (String value) {
                              setState(() {});
                              ref.read(movieNotifierProvider.notifier).searchMovies(value);
                            },
                            onClear: () {
                              _searchController.clear();
                              setState(() {});
                              ref.read(movieNotifierProvider.notifier).searchMovies('');
                            },
                          ),
                        ),
                      ],
                    )
                  else ...[
                    const Text(
                      'Movies',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    _SearchBar(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onChanged: (String value) {
                        setState(() {});
                        ref.read(movieNotifierProvider.notifier).searchMovies(value);
                      },
                      onClear: () {
                        _searchController.clear();
                        setState(() {});
                        ref.read(movieNotifierProvider.notifier).searchMovies('');
                      },
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Genre pills - horizontal wrap
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kMovieGenres.map((GenreItem genre) {
                      final bool selected = selectedGenre == genre.label;
                      return GenrePill(
                        label: genre.label,
                        icon: genre.icon,
                        isSelected: selected,
                        onTap: () {
                          if (selectedGenre == genre.label) {
                            ref.read(movieNotifierProvider.notifier).filterByGenre(null);
                          } else {
                            ref.read(movieNotifierProvider.notifier).filterByGenre(genre.label);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // Divider
                  Container(height: 1, color: const Color(0xFF1A1A1A)),
                ],
              ),
            ),
          ),

          // ── Results header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
              child: Row(
                children: [
                  Text(
                    hasQuery ? 'Results' : 'Featured Movies',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  if (movieState.searchResults.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${movieState.searchResults.length > 40 ? "40+" : movieState.searchResults.length}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Movie grid ──
          movieState.status == MovieStatus.loading
              ? const SliverLoadingView(message: 'Loading movies...')
              : movieState.status == MovieStatus.error
                  ? SliverErrorView(
                      title: 'Failed to load movies',
                      message: movieState.errorMessage,
                      onRetry: () => ref.read(movieNotifierProvider.notifier).loadMovies(),
                    )
                  : movieState.searchResults.isEmpty
                      ? const SliverEmptyView(
                          icon: Icons.movie_filter,
                          title: 'No movies found',
                          message: 'Try a different search or genre',
                        )
                      : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          childAspectRatio: 0.52,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 24,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            final MovieModel movie = movieState.searchResults[index];
                            return MovieCard(
                              movie: movie,
                              width: double.infinity,
                              height: 220,
                              subtitle: selectedGenre,
                              onTap: () => context.push('/movie/${movie.movieId}'),
                            );
                          },
                          childCount: movieState.searchResults.length > 40 ? 40 : movieState.searchResults.length,
                        ),
                      ),
                    ),

          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }
}

// ── Search bar ──
class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.controller, required this.focusNode, required this.onChanged, required this.onClear});

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 42,
      decoration: BoxDecoration(
        color: _focused ? const Color(0xFF1A1A1A) : const Color(0xFF121212),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _focused ? AppColors.primary.withValues(alpha: 0.5) : const Color(0xFF2A2A2A),
          width: 1,
        ),
        boxShadow: _focused
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 12)]
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, color: _focused ? AppColors.primary : const Color(0xFF555555), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              onChanged: widget.onChanged,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              cursorColor: AppColors.primary,
              decoration: const InputDecoration(
                hintText: 'Search movies or genres...',
                hintStyle: TextStyle(color: Color(0xFF555555), fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            GestureDetector(
              onTap: widget.onClear,
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.close_rounded, color: AppColors.grey500, size: 14),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}

