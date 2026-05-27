import 'package:movie_recommender_web/models/movie_model.dart';

class FavoritesState {
  final List<MovieModel> favorites;
  final bool isLoading;
  final String? errorMessage;

  const FavoritesState({
    this.favorites = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  FavoritesState copyWith({
    List<MovieModel>? favorites,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FavoritesState(
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  bool isFavorite(String movieId) {
    return favorites.any((MovieModel m) => m.movieId == movieId);
  }
}
