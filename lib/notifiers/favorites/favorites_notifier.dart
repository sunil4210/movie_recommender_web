import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommender_web/models/movie_model.dart';
import 'package:movie_recommender_web/notifiers/favorites/favorites_state.dart';
import 'package:movie_recommender_web/services/favorite_service.dart';
import 'package:movie_recommender_web/services/service_providers.dart';

/// State holder for the user's favourites list.
///
/// Mutations apply optimistically so the UI feels snappy; if the backend
/// call fails the previous list is restored so users don't see "ghost" rows.
class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier(this._service) : super(const FavoritesState());

  final FavoriteService _service;

  Future<void> loadFavorites(int userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _service.list(userId);
    result.when(
      success: (favs) =>
          state = state.copyWith(favorites: favs, isLoading: false),
      failure: (e) =>
          state = state.copyWith(isLoading: false, errorMessage: e.message),
    );
  }

  Future<void> toggleFavorite(MovieModel movie, int userId) async {
    final List<MovieModel> previous = List<MovieModel>.from(state.favorites);
    final List<MovieModel> next = List<MovieModel>.from(state.favorites);
    final bool removing = state.isFavorite(movie.movieId);

    if (removing) {
      next.removeWhere((m) => m.movieId == movie.movieId);
    } else {
      next.add(movie);
    }
    state = state.copyWith(favorites: next);

    final result = removing
        ? await _service.remove(userId: userId, movieId: movie.id)
        : await _service.add(userId: userId, movieId: movie.id);
    result.when(
      success: (_) {},
      failure: (_) => state = state.copyWith(favorites: previous),
    );
  }

  Future<void> removeFavorite(String movieId, int userId) async {
    final List<MovieModel> next = List<MovieModel>.from(state.favorites)
      ..removeWhere((m) => m.movieId == movieId);
    state = state.copyWith(favorites: next);
    await _service.remove(userId: userId, movieId: int.parse(movieId));
  }

  Future<void> clearAll(int userId) async {
    final List<MovieModel> snapshot = List<MovieModel>.from(state.favorites);
    state = state.copyWith(favorites: const []);
    for (final MovieModel m in snapshot) {
      await _service.remove(userId: userId, movieId: m.id);
    }
  }
}

final StateNotifierProvider<FavoritesNotifier, FavoritesState>
    favoritesNotifierProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>(
  (Ref ref) => FavoritesNotifier(ref.read(favoriteServiceProvider)),
);
