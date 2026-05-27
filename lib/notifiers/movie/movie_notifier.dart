import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommender_web/models/movie_model.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_notifier.dart';
import 'package:movie_recommender_web/notifiers/movie/movie_state.dart';
import 'package:movie_recommender_web/services/database_service.dart';

/// Riverpod notifier that owns all movie-related state: catalog, popular, trending,
/// new arrivals, recommendations, and the current search/filter view.
///
/// One instance per app — held by `movieNotifierProvider`. UI pages read from
/// `MovieState` and call the methods below to fetch or filter data.
class MovieNotifier extends StateNotifier<MovieState> {
  final DatabaseService _databaseService;

  MovieNotifier(this._databaseService) : super(const MovieState());

  /// Fetch the full movie catalog plus the popular/trending rails in parallel.
  /// On error, popular/trending fall back to local sorts of the catalog so the
  /// home page is never empty.
  Future<void> loadMovies() async {
    state = state.copyWith(status: MovieStatus.loading);

    // Fetch all movies, popular, and trending in parallel
    final results = await Future.wait([
      _databaseService.getMovies(perPage: 200),
      _databaseService.getPopularMovies(limit: 10),
      _databaseService.getTrendingMovies(limit: 10),
    ]);

    final allResult = results[0];
    final popularResult = results[1];
    final trendingResult = results[2];

    allResult.when(
      success: (List<MovieModel> movies) {
        // New arrivals = latest release year
        final List<MovieModel> newArrivals = List<MovieModel>.from(movies)
          ..sort((a, b) => (b.releaseYear ?? 0).compareTo(a.releaseYear ?? 0));

        List<MovieModel> popular = [];
        popularResult.when(
          success: (data) => popular = data,
          failure: (_) {
            // Fallback: sort all movies by rating
            popular = (List<MovieModel>.from(movies)
                  ..sort((a, b) => b.avgRating.compareTo(a.avgRating)))
                .take(10)
                .toList();
          },
        );

        List<MovieModel> trending = [];
        trendingResult.when(
          success: (data) => trending = data,
          failure: (_) {
            trending = (List<MovieModel>.from(movies)
                  ..sort(
                      (a, b) => b.totalRatings.compareTo(a.totalRatings)))
                .take(10)
                .toList();
          },
        );

        final String? activeGenre = state.selectedGenre;
        final String activeQuery = state.searchQuery;
        List<MovieModel> results = movies;
        if (activeGenre != null && activeGenre != 'All') {
          results = movies
              .where((MovieModel m) => m.genres.any(
                    (String g) => g.toLowerCase() == activeGenre.toLowerCase(),
                  ))
              .toList();
        } else if (activeQuery.isNotEmpty) {
          final String lower = activeQuery.toLowerCase();
          results = movies.where((MovieModel movie) {
            return movie.title.toLowerCase().contains(lower) ||
                movie.genres.any((String g) => g.toLowerCase().contains(lower));
          }).toList();
        }

        state = state.copyWith(
          status: MovieStatus.loaded,
          allMovies: movies,
          popularMovies: popular,
          trendingMovies: trending,
          newArrivals: newArrivals.take(10).toList(),
          searchResults: results,
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

  /// Fetch personalized recommendations for [userId].
  ///
  /// The frontend always passes `algorithm: 'user_user'`. The default parameter is
  /// kept as 'svd' so ad-hoc curl/test calls without a query param still work,
  /// matching the backend's default.
  ///
  /// If the backend call fails (network/cold-start/etc.), recommendations fall back
  /// to whatever is in `popularMovies` so the UI never shows an empty rail.
  Future<void> loadRecommendations(int userId, {String algorithm = 'svd'}) async {
    final result = await _databaseService.getRecommendations(userId, algorithm: algorithm);
    result.when(
      success: (recs) => state = state.copyWith(recommendations: recs),
      failure: (_) {
        state = state.copyWith(recommendations: state.popularMovies);
      },
    );
  }

  /// Filter the catalog client-side by title or genre substring.
  /// Empty query restores the full catalog into `searchResults`.
  void searchMovies(String query) {
    final String lowerQuery = query.toLowerCase();
    state = state.copyWith(searchQuery: query);

    if (query.isEmpty) {
      state = state.copyWith(searchResults: state.allMovies);
      return;
    }

    final List<MovieModel> results =
        state.allMovies.where((MovieModel movie) {
      return movie.title.toLowerCase().contains(lowerQuery) ||
          movie.genres
              .any((String g) => g.toLowerCase().contains(lowerQuery));
    }).toList();

    state = state.copyWith(searchResults: results);
  }

  /// Filter the catalog to movies whose genre list contains [genre] (case-insensitive).
  /// Pass `null` or `'All'` to clear the filter and show every movie.
  /// Match is "any of the movie's genres equals [genre]" — so a movie tagged
  /// `Action|Comedy|Drama` matches when filtering by any one of those three.
  void filterByGenre(String? genre) {
    state = state.copyWith(selectedGenre: genre);

    if (genre == null || genre == 'All') {
      state = state.copyWith(searchResults: state.allMovies);
      return;
    }

    final List<MovieModel> filtered = state.allMovies
        .where((MovieModel m) => m.genres.any(
              (String g) => g.toLowerCase() == genre.toLowerCase(),
            ))
        .toList();

    state = state.copyWith(searchResults: filtered);
  }

  void setRecommendations(List<MovieModel> recs) {
    state = state.copyWith(recommendations: recs);
  }
}

final Provider<DatabaseService> databaseServiceProvider =
    Provider<DatabaseService>(
  (Ref ref) {
    final authService = ref.read(authServiceProvider);
    return DatabaseService(getHeaders: () => authService.authHeaders);
  },
);

final StateNotifierProvider<MovieNotifier, MovieState> movieNotifierProvider =
    StateNotifierProvider<MovieNotifier, MovieState>(
  (Ref ref) => MovieNotifier(ref.read(databaseServiceProvider)),
);
