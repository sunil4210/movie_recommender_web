import 'dart:async';

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
  static const Duration _debounce = Duration(milliseconds: 300);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounceTimer;
  bool _isSearching = false;

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
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () async {
      if (!mounted) return;
      setState(() => _isSearching = true);
      await ref.read(movieNotifierProvider.notifier).searchMovies(value);
      if (!mounted) return;
      setState(() => _isSearching = false);
    });
  }

  void _clearQuery() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() => _isSearching = false);
    final MovieNotifier notifier = ref.read(movieNotifierProvider.notifier);
    // Full reset: clear text AND drop any active genre filter so the page
    // returns to the default catalog view.
    notifier.filterByGenre(null);
    notifier.searchMovies('');
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
                            isLoading: _isSearching,
                            onChanged: _onQueryChanged,
                            onClear: _clearQuery,
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
                      isLoading: _isSearching,
                      onChanged: _onQueryChanged,
                      onClear: _clearQuery,
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
                              onTap: () => context.go('/movie/${movie.movieId}'),
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
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    this.isLoading = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isLoading;

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
    final bool hasText = widget.controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      decoration: BoxDecoration(
        color: _focused ? const Color(0xFF1A1A1A) : const Color(0xFF121212),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _focused ? AppColors.primary.withValues(alpha: 0.5) : const Color(0xFF2A2A2A),
          width: 1,
        ),
        boxShadow: _focused
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.06), blurRadius: 14)]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 18),
          Icon(
            Icons.search_rounded,
            color: _focused ? AppColors.primary : const Color(0xFF555555),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              onChanged: widget.onChanged,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              cursorColor: AppColors.primary,
              decoration: const InputDecoration(
                hintText: 'Search movies or genres…',
                hintStyle: TextStyle(color: Color(0xFF555555), fontSize: 15),
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.isLoading) ...[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(width: 18),
          ] else if (hasText)
            _ClearButton(onTap: widget.onClear)
          else
            const SizedBox(width: 18),
        ],
      ),
    );
  }
}

class _ClearButton extends StatefulWidget {
  const _ClearButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ClearButton> createState() => _ClearButtonState();
}

class _ClearButtonState extends State<_ClearButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, left: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Icon(
            Icons.close_rounded,
            color: _hovered ? Colors.white : const Color(0xFF888888),
            size: 20,
          ),
        ),
      ),
    );
  }
}

