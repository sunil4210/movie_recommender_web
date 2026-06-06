import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:movie_recommender_web/core/constants/api_constants.dart';
import 'package:movie_recommender_web/core/exceptions/async_result.dart';
import 'package:movie_recommender_web/models/movie_model.dart';
import 'package:movie_recommender_web/services/api_client.dart';

/// HTTP wrapper for /api/favorites/* endpoints.
class FavoriteService {
  FavoriteService(this._api);

  final ApiClient _api;

  Future<AsyncResult<List<MovieModel>>> list(int userId) {
    return runCatching<List<MovieModel>>(() async {
      final http.Response res =
          await _api.get(Uri.parse(ApiConstants.favoritesForUser(userId)));
      ApiClient.ensureOk(res);

      final List<dynamic> rows = jsonDecode(res.body) as List<dynamic>;
      return rows.map((dynamic item) {
        // Backend returns favorite rows with `movie_id` / `movie_title` etc.,
        // not a nested movie object — flatten into MovieModel here so notifiers
        // can treat favourites and catalog movies uniformly.
        final Map<String, dynamic> m = item as Map<String, dynamic>;
        return MovieModel(
          id: m['movie_id'] as int,
          title: m['movie_title'] as String? ?? '',
          genres: List<String>.from(m['genres'] ?? <String>[]),
          posterUrl: m['poster_url'] as String?,
          blurHash: m['blur_hash'] as String?,
          avgRating: (m['average_rating'] as num?)?.toDouble() ?? 0.0,
          totalRatings: (m['total_ratings'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    });
  }

  Future<AsyncResult<void>> add({
    required int userId,
    required int movieId,
  }) {
    return runCatching<void>(() async {
      ApiClient.ensureOk(await _api.post(
        Uri.parse(ApiConstants.favorites),
        body: <String, dynamic>{'user_id': userId, 'movie_id': movieId},
      ));
    });
  }

  Future<AsyncResult<void>> remove({
    required int userId,
    required int movieId,
  }) {
    return runCatching<void>(() async {
      ApiClient.ensureOk(await _api.delete(
        Uri.parse(ApiConstants.favoriteByUserMovie(userId, movieId)),
      ));
    });
  }
}
