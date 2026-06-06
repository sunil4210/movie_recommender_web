import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:movie_recommender_web/core/constants/api_constants.dart';
import 'package:movie_recommender_web/core/exceptions/async_result.dart';
import 'package:movie_recommender_web/models/rating_model.dart';
import 'package:movie_recommender_web/services/api_client.dart';

/// HTTP wrapper for /api/ratings/* endpoints.
class RatingService {
  RatingService(this._api);

  final ApiClient _api;

  Future<AsyncResult<void>> submit({
    required int userId,
    required int movieId,
    required double rating,
    String? comment,
  }) {
    return runCatching<void>(() async {
      final Map<String, dynamic> body = <String, dynamic>{
        'user_id': userId,
        'movie_id': movieId,
        'rating': rating,
      };
      // Only send the field when supplied — backend treats absent vs empty
      // differently (keep prior comment vs clear it).
      if (comment != null) body['comment'] = comment;
      ApiClient.ensureOk(
        await _api.post(Uri.parse(ApiConstants.ratings), body: body),
      );
    });
  }

  Future<AsyncResult<List<MovieReviewModel>>> reviewsForMovie(
    int movieId, {
    int limit = 1000,
    String sort = 'newest',
    int? pinUserId,
  }) {
    return runCatching<List<MovieReviewModel>>(() async {
      final Map<String, String> params = <String, String>{
        'limit': limit.toString(),
        'sort': sort,
      };
      if (pinUserId != null) params['pin_user_id'] = pinUserId.toString();

      final http.Response res = await _api.get(
        Uri.parse(ApiConstants.reviewsForMovie(movieId))
            .replace(queryParameters: params),
      );
      ApiClient.ensureOk(res);
      final List<dynamic> rows = jsonDecode(res.body) as List<dynamic>;
      return rows
          .map((dynamic r) =>
              MovieReviewModel.fromMap(r as Map<String, dynamic>))
          .toList();
    });
  }

  /// Returns `Success(null)` when the user has no rating on the movie yet.
  Future<AsyncResult<RatingModel?>> myRating(int userId, int movieId) {
    return runCatching<RatingModel?>(() async {
      final http.Response res =
          await _api.get(Uri.parse(ApiConstants.userMovieRating(userId, movieId)));
      if (res.statusCode == 404) return null;
      ApiClient.ensureOk(res);
      if (res.body.isEmpty || res.body == 'null') return null;
      final dynamic decoded = jsonDecode(res.body);
      if (decoded == null) return null;
      return RatingModel.fromMap(decoded as Map<String, dynamic>);
    });
  }
}
