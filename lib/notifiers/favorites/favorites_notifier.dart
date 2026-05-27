import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommender_web/models/movie_model.dart';
import 'package:movie_recommender_web/notifiers/favorites/favorites_state.dart';
import 'package:movie_recommender_web/notifiers/movie/movie_notifier.dart';
import 'package:movie_recommender_web/services/database_service.dart';

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final DatabaseService _databaseService;

  FavoritesNotifier(this._databaseService) : super(const FavoritesState());

  Future<void> loadFavorites(int userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _databaseService.getFavorites(userId);
    result.when(
      success: (favs) =>
          state = state.copyWith(favorites: favs, isLoading: false),
      failure: (e) => state = state.copyWith(
          isLoading: false, errorMessage: e.message),
    );
  }

  Future<void> toggleFavorite(MovieModel movie, int userId) async {
    final List<MovieModel> previousFavorites = List<MovieModel>.from(state.favorites);
    final List<MovieModel> current = List<MovieModel>.from(state.favorites);

    if (state.isFavorite(movie.movieId)) {
      // Remove — update local state first, then call backend
      current.removeWhere((MovieModel m) => m.movieId == movie.movieId);
      state = state.copyWith(favorites: current);
      final result = await _databaseService.removeFavorite(
          userId: userId, movieId: movie.id);
      result.when(
        success: (_) {},
        failure: (_) => state = state.copyWith(favorites: previousFavorites),
      );
    } else {
      // Add — update local state first, then call backend
      current.add(movie);
      state = state.copyWith(favorites: current);
      final result = await _databaseService.addFavorite(
          userId: userId, movieId: movie.id);
      result.when(
        success: (_) {},
        failure: (_) => state = state.copyWith(favorites: previousFavorites),
      );
    }
  }

  Future<void> removeFavorite(String movieId, int userId) async {
    final List<MovieModel> current = List<MovieModel>.from(state.favorites);
    current.removeWhere((MovieModel m) => m.movieId == movieId);
    state = state.copyWith(favorites: current);
    await _databaseService.removeFavorite(
        userId: userId, movieId: int.parse(movieId));
  }

  Future<void> clearAll(int userId) async {
    final List<MovieModel> current = List<MovieModel>.from(state.favorites);
    state = state.copyWith(favorites: []);
    // Remove each from backend
    for (final MovieModel movie in current) {
      await _databaseService.removeFavorite(
          userId: userId, movieId: movie.id);
    }
  }
}

final StateNotifierProvider<FavoritesNotifier, FavoritesState>
    favoritesNotifierProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>(
  (Ref ref) =>
      FavoritesNotifier(ref.read(databaseServiceProvider)),
);
