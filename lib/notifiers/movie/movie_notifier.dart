import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommender_web/core/exceptions/async_result.dart';
import 'package:movie_recommender_web/models/movie_model.dart';
import 'package:movie_recommender_web/notifiers/movie/movie_state.dart';
import 'package:movie_recommender_web/services/movie_service.dart';
import 'package:movie_recommender_web/services/recommendation_service.dart';
import 'package:movie_recommender_web/services/service_providers.dart';

/// State holder for the movie catalog, the home-page rails (popular / trending /
/// new arrivals), the current search results, and recommendations.
///
/// All HTTP is delegated to [MovieService] / [RecommendationService] — this
/// class only manages state and the cross-rail orchestration.
class MovieNotifier extends StateNotifier<MovieState> {
  MovieNotifier(this._movieService, this._recommendationService)
      : super(const MovieState());

  final MovieService _movieService;
  final RecommendationService _recommendationService;

  int _searchRequestId = 0;

  /// Hydrate the catalog + the popular/trending rails in parallel. If popular
  /// or trending fail, we derive them from the catalog so the home page never
  /// renders empty rails.
  Future<void> loadMovies() async {
    state = state.copyWith(status: MovieStatus.loading);

    final results = await Future.wait([
      _movieService.list(perPage: 200),
      _movieService.popular(limit: 10),
      _movieService.trending(limit: 10),
    ]);

    final AsyncResult<List<MovieModel>> allResult = results[0];
    final AsyncResult<List<MovieModel>> popularResult = results[1];
    final AsyncResult<List<MovieModel>> trendingResult = results[2];

    allResult.when(
      success: (List<MovieModel> movies) {
        final List<MovieModel> newArrivals = List<MovieModel>.from(movies)
          ..sort((a, b) => (b.releaseYear ?? 0).compareTo(a.releaseYear ?? 0));

        List<MovieModel> popular = const [];
        popularResult.when(
          success: (List<MovieModel> data) => popular = data,
          failure: (_) {
            popular = (List<MovieModel>.from(movies)
                  ..sort((a, b) => b.avgRating.compareTo(a.avgRating)))
                .take(10)
                .toList();
          },
        );

        List<MovieModel> trending = const [];
        trendingResult.when(
          success: (List<MovieModel> data) => trending = data,
          failure: (_) {
            trending = (List<MovieModel>.from(movies)
                  ..sort((a, b) => b.totalRatings.compareTo(a.totalRatings)))
                .take(10)
                .toList();
          },
        );

        state = state.copyWith(
          status: MovieStatus.loaded,
          allMovies: movies,
          popularMovies: popular,
          trendingMovies: trending,
          newArrivals: newArrivals.take(10).toList(),
          searchResults: _filterLocally(
            movies,
            state.searchQuery,
            state.selectedGenre,
          ),
        );
      },
      failure: (exception) {
        state = state.copyWith(
          status: MovieStatus.error,
          errorMessage: exception.message,
        );
      },
    );
  }

  /// Pull personalised recommendations. Falls back to the popular rail if the
  /// backend call fails so the UI never shows an empty "Recommended" section.
  Future<void> loadRecommendations(int userId, {String algorithm = 'svd'}) async {
    final result =
        await _recommendationService.forUser(userId, algorithm: algorithm);
    result.when(
      success: (recs) => state = state.copyWith(recommendations: recs),
      failure: (_) =>
          state = state.copyWith(recommendations: state.popularMovies),
    );
  }

  Future<void> searchMovies(String query) async {
    state = state.copyWith(searchQuery: query);
    await _runSearch();
  }

  Future<void> filterByGenre(String? genre) async {
    state = state.copyWith(selectedGenre: genre);
    await _runSearch();
  }

  /// Hits the backend search endpoint so we get token-aware ranking. A stale
  /// in-flight response is dropped via `_searchRequestId` so fast typing can't
  /// race a slower query into the UI.
  Future<void> _runSearch() async {
    final String query = state.searchQuery.trim();
    final String? raw = state.selectedGenre;
    final String? genre = (raw == null || raw == 'All') ? null : raw;
    final int requestId = ++_searchRequestId;

    final AsyncResult<List<MovieModel>> result = await _movieService.list(
      searchQuery: query.isEmpty ? null : query,
      genre: genre,
      perPage: 60,
    );

    if (requestId != _searchRequestId) return;

    result.when(
      success: (movies) => state = state.copyWith(searchResults: movies),
      failure: (_) => state = state.copyWith(
        searchResults: _filterLocally(state.allMovies, query, genre),
      ),
    );
  }

  /// Offline fallback filter — used when the backend search fails so the page
  /// still shows something derived from the catalog already in memory.
  static List<MovieModel> _filterLocally(
    List<MovieModel> source,
    String query,
    String? genre,
  ) {
    final String lower = query.toLowerCase();
    Iterable<MovieModel> base = source;
    if (genre != null && genre != 'All') {
      base = base.where((m) =>
          m.genres.any((g) => g.toLowerCase() == genre.toLowerCase()));
    }
    if (lower.isNotEmpty) {
      base = base.where((m) =>
          m.title.toLowerCase().contains(lower) ||
          m.genres.any((g) => g.toLowerCase().contains(lower)));
    }
    return base.toList();
  }
}

final StateNotifierProvider<MovieNotifier, MovieState> movieNotifierProvider =
    StateNotifierProvider<MovieNotifier, MovieState>(
  (Ref ref) => MovieNotifier(
    ref.read(movieServiceProvider),
    ref.read(recommendationServiceProvider),
  ),
);
