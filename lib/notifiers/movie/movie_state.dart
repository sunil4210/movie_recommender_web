import 'package:movie_recommender_web/models/movie_model.dart';

enum MovieStatus { initial, loading, loaded, error }

class MovieState {
  final MovieStatus status;
  final List<MovieModel> allMovies;
  final List<MovieModel> popularMovies;
  final List<MovieModel> trendingMovies;
  final List<MovieModel> newArrivals;
  final List<MovieModel> recommendations;
  final List<MovieModel> searchResults;
  final String? selectedGenre;
  final String searchQuery;
  final String? errorMessage;

  const MovieState({
    this.status = MovieStatus.initial,
    this.allMovies = const [],
    this.popularMovies = const [],
    this.trendingMovies = const [],
    this.newArrivals = const [],
    this.recommendations = const [],
    this.searchResults = const [],
    this.selectedGenre,
    this.searchQuery = '',
    this.errorMessage,
  });

  static const Object _unset = Object();

  MovieState copyWith({
    MovieStatus? status,
    List<MovieModel>? allMovies,
    List<MovieModel>? popularMovies,
    List<MovieModel>? trendingMovies,
    List<MovieModel>? newArrivals,
    List<MovieModel>? recommendations,
    List<MovieModel>? searchResults,
    Object? selectedGenre = _unset,
    String? searchQuery,
    Object? errorMessage = _unset,
  }) {
    return MovieState(
      status: status ?? this.status,
      allMovies: allMovies ?? this.allMovies,
      popularMovies: popularMovies ?? this.popularMovies,
      trendingMovies: trendingMovies ?? this.trendingMovies,
      newArrivals: newArrivals ?? this.newArrivals,
      recommendations: recommendations ?? this.recommendations,
      searchResults: searchResults ?? this.searchResults,
      selectedGenre: identical(selectedGenre, _unset) ? this.selectedGenre : selectedGenre as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: identical(errorMessage, _unset) ? this.errorMessage : errorMessage as String?,
    );
  }
}
