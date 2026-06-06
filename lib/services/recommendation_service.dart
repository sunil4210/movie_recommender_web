import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:movie_recommender_web/core/constants/api_constants.dart';
import 'package:movie_recommender_web/core/exceptions/async_result.dart';
import 'package:movie_recommender_web/models/movie_model.dart';
import 'package:movie_recommender_web/services/api_client.dart';

/// HTTP wrapper for /api/recommendations/* endpoints.
class RecommendationService {
  RecommendationService(this._api);

  final ApiClient _api;

  /// Personalised recommendations for [userId]. The frontend pins
  /// `algorithm: 'user_user'` in production; the param exists so the
  /// metrics tab / curl users can still pick svd or item_item.
  Future<AsyncResult<List<MovieModel>>> forUser(
    int userId, {
    int n = 10,
    String algorithm = 'svd',
  }) {
    return _recList(
      ApiConstants.recommendationsFor(userId),
      <String, String>{'n': n.toString(), 'algorithm': algorithm},
    );
  }

  Future<AsyncResult<List<MovieModel>>> similar(
    int userId,
    int movieId, {
    int n = 10,
  }) {
    return _recList(
      ApiConstants.similarMovies(userId, movieId),
      <String, String>{'n': n.toString()},
    );
  }

  Future<AsyncResult<List<MovieModel>>> _recList(
    String endpoint,
    Map<String, String> params,
  ) {
    return runCatching<List<MovieModel>>(() async {
      final http.Response res =
          await _api.get(Uri.parse(endpoint).replace(queryParameters: params));
      ApiClient.ensureOk(res);
      final List<dynamic> rows = jsonDecode(res.body) as List<dynamic>;
      return rows
          .map((dynamic m) =>
              MovieModel.fromRecommendation(m as Map<String, dynamic>))
          .toList();
    });
  }
}
