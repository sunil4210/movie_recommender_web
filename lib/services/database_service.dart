import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:movie_recommender_web/core/constants/api_constants.dart';
import 'package:movie_recommender_web/core/exceptions/app_exception.dart';
import 'package:movie_recommender_web/core/exceptions/async_result.dart';
import 'package:movie_recommender_web/models/movie_model.dart';
import 'package:movie_recommender_web/models/rating_model.dart';
import 'package:pretty_http_logger/pretty_http_logger.dart';

class DatabaseService {
  final http.Client _client = HttpClientWithMiddleware.build(
    middlewares: [HttpLogger(logLevel: LogLevel.BODY)],
  );
  final Map<String, String> Function() _getHeaders;

  DatabaseService({required Map<String, String> Function() getHeaders})
      : _getHeaders = getHeaders;

  // ---- Movies ----

  Future<AsyncResult<List<MovieModel>>> getMovies({
    String? genre,
    String? searchQuery,
    int page = 1,
    int perPage = 100,
  }) async {
    return runCatching<List<MovieModel>>(() async {
      // Use search endpoint if we have query or genre filter
      final bool useSearch =
          (searchQuery != null && searchQuery.isNotEmpty) ||
              (genre != null && genre != 'All');

      final Map<String, String> queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      String endpoint = '${ApiConstants.baseUrl}/movies';
      if (useSearch) {
        endpoint = '${ApiConstants.baseUrl}/movies/search';
        if (searchQuery != null && searchQuery.isNotEmpty) {
          queryParams['q'] = searchQuery;
        }
        if (genre != null && genre != 'All') {
          queryParams['genre'] = genre;
        }
      }

      final Uri uri =
          Uri.parse(endpoint).replace(queryParameters: queryParams);
      final http.Response response =
          await _client.get(uri, headers: _getHeaders());

      if (response.statusCode != 200) {
        throw AppException.fromStatusCode(response.statusCode);
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> moviesJson = data['movies'] as List<dynamic>;
      return moviesJson
          .map((dynamic item) =>
              MovieModel.fromMap(item as Map<String, dynamic>))
          .toList();
    });
  }

  Future<AsyncResult<MovieModel?>> getMovie(int movieId) async {
    return runCatching<MovieModel?>(() async {
      final http.Response response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/movies/$movieId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw AppException.fromStatusCode(response.statusCode);
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return MovieModel.fromMap(data);
    });
  }

  Future<AsyncResult<List<MovieModel>>> getPopularMovies(
      {int limit = 20}) async {
    return runCatching<List<MovieModel>>(() async {
      final http.Response response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/movies/popular?limit=$limit'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw AppException.fromStatusCode(response.statusCode);
      }

      final List<dynamic> data =
          jsonDecode(response.body) as List<dynamic>;
      return data
          .map((dynamic item) =>
              MovieModel.fromMap(item as Map<String, dynamic>))
          .toList();
    });
  }

  Future<AsyncResult<List<MovieModel>>> getTrendingMovies(
      {int limit = 20}) async {
    return runCatching<List<MovieModel>>(() async {
      final http.Response response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/movies/trending?limit=$limit'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw AppException.fromStatusCode(response.statusCode);
      }

      final List<dynamic> data =
          jsonDecode(response.body) as List<dynamic>;
      return data
          .map((dynamic item) =>
              MovieModel.fromMap(item as Map<String, dynamic>))
          .toList();
    });
  }

  // ---- Recommendations ----

  Future<AsyncResult<List<MovieModel>>> getRecommendations(
      int userId,
      {int n = 10, String algorithm = 'svd'}) async {
    return runCatching<List<MovieModel>>(() async {
      final http.Response response = await _client.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/recommendations/$userId?n=$n&algorithm=$algorithm'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw AppException.fromStatusCode(response.statusCode);
      }

      final List<dynamic> data =
          jsonDecode(response.body) as List<dynamic>;
      return data
          .map((dynamic item) =>
              MovieModel.fromRecommendation(item as Map<String, dynamic>))
          .toList();
    });
  }

  Future<AsyncResult<List<MovieModel>>> getSimilarMovies(
      int userId, int movieId,
      {int n = 10}) async {
    return runCatching<List<MovieModel>>(() async {
      final http.Response response = await _client.get(
        Uri.parse(
            '${ApiConstants.baseUrl}/recommendations/$userId/similar/$movieId?n=$n'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw AppException.fromStatusCode(response.statusCode);
      }

      final List<dynamic> data =
          jsonDecode(response.body) as List<dynamic>;
      return data
          .map((dynamic item) =>
              MovieModel.fromRecommendation(item as Map<String, dynamic>))
          .toList();
    });
  }

  // ---- Ratings ----

  Future<AsyncResult<void>> submitRating({
    required int userId,
    required int movieId,
    required double rating,
  }) async {
    return runCatching<void>(() async {
      final http.Response response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/ratings'),
        headers: _getHeaders(),
        body: jsonEncode({
          'user_id': userId,
          'movie_id': movieId,
          'rating': rating,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw AppException.fromStatusCode(response.statusCode);
      }
    });
  }

  Future<AsyncResult<List<RatingModel>>> getUserRatings(int userId) async {
    return runCatching<List<RatingModel>>(() async {
      final http.Response response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/ratings/user/$userId'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw AppException.fromStatusCode(response.statusCode);
      }

      final List<dynamic> data =
          jsonDecode(response.body) as List<dynamic>;
      return data
          .map((dynamic item) =>
              RatingModel.fromMap(item as Map<String, dynamic>))
          .toList();
    });
  }

  // ---- Feedback (like/dislike) ----

  Future<AsyncResult<void>> submitFeedback({
    required int userId,
    required int movieId,
    required String feedbackType,
  }) async {
    return runCatching<void>(() async {
      final http.Response response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/feedback'),
        headers: _getHeaders(),
        body: jsonEncode({
          'user_id': userId,
          'movie_id': movieId,
          'feedback_type': feedbackType,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw AppException.fromStatusCode(response.statusCode);
      }
    });
  }

  // ---- Favorites ----

  Future<AsyncResult<List<MovieModel>>> getFavorites(int userId) async {
    return runCatching<List<MovieModel>>(() async {
      final http.Response response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/favorites/$userId'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw AppException.fromStatusCode(response.statusCode);
      }

      final List<dynamic> data =
          jsonDecode(response.body) as List<dynamic>;
      return data.map((dynamic item) {
        final Map<String, dynamic> map = item as Map<String, dynamic>;
        return MovieModel(
          id: map['movie_id'] as int,
          title: map['movie_title'] as String? ?? '',
          genres: List<String>.from(map['genres'] ?? []),
          posterUrl: map['poster_url'] as String?,
          blurHash: map['blur_hash'] as String?,
          avgRating: (map['average_rating'] as num?)?.toDouble() ?? 0.0,
          totalRatings: (map['total_ratings'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    });
  }

  Future<AsyncResult<void>> addFavorite({
    required int userId,
    required int movieId,
  }) async {
    return runCatching<void>(() async {
      final http.Response response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/favorites'),
        headers: _getHeaders(),
        body: jsonEncode({
          'user_id': userId,
          'movie_id': movieId,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw AppException.fromStatusCode(response.statusCode);
      }
    });
  }

  Future<AsyncResult<void>> removeFavorite({
    required int userId,
    required int movieId,
  }) async {
    return runCatching<void>(() async {
      final http.Response response = await _client.delete(
        Uri.parse('${ApiConstants.baseUrl}/favorites/$userId/$movieId'),
        headers: _getHeaders(),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw AppException.fromStatusCode(response.statusCode);
      }
    });
  }
}
