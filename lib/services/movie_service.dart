import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:movie_recommender_web/core/constants/api_constants.dart';
import 'package:movie_recommender_web/core/exceptions/async_result.dart';
import 'package:movie_recommender_web/models/movie_model.dart';
import 'package:movie_recommender_web/services/api_client.dart';

/// HTTP wrapper for /api/movies/* endpoints.
class MovieService {
  MovieService(this._api);

  final ApiClient _api;

  /// Catalog list + search + genre filter. Backend `/search` is used whenever
  /// either `searchQuery` or `genre` is supplied so token-aware ranking kicks
  /// in instead of plain LIKE.
  Future<AsyncResult<List<MovieModel>>> list({
    String? searchQuery,
    String? genre,
    int page = 1,
    int perPage = 100,
  }) {
    return runCatching<List<MovieModel>>(() async {
      final bool useSearch = (searchQuery != null && searchQuery.isNotEmpty) ||
          (genre != null && genre != 'All');

      final Map<String, String> params = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      String endpoint = ApiConstants.movies;
      if (useSearch) {
        endpoint = ApiConstants.moviesSearch;
        if (searchQuery != null && searchQuery.isNotEmpty) {
          params['q'] = searchQuery;
        }
        if (genre != null && genre != 'All') {
          params['genre'] = genre;
        }
      }

      final http.Response res =
          await _api.get(Uri.parse(endpoint).replace(queryParameters: params));
      ApiClient.ensureOk(res);

      final Map<String, dynamic> data =
          jsonDecode(res.body) as Map<String, dynamic>;
      final List<dynamic> rows = data['movies'] as List<dynamic>;
      return rows
          .map((dynamic m) => MovieModel.fromMap(m as Map<String, dynamic>))
          .toList();
    });
  }

  /// Single movie by id. Returns `Success(null)` on 404 so the caller can
  /// render a friendly "not found" state without treating it as an error.
  Future<AsyncResult<MovieModel?>> getById(int movieId) {
    return runCatching<MovieModel?>(() async {
      final http.Response res =
          await _api.get(Uri.parse(ApiConstants.movieById(movieId)));
      if (res.statusCode == 404) return null;
      ApiClient.ensureOk(res);
      return MovieModel.fromMap(jsonDecode(res.body) as Map<String, dynamic>);
    });
  }

  Future<AsyncResult<List<MovieModel>>> popular({int limit = 20}) {
    return _movieList(ApiConstants.moviesPopular, limit);
  }

  Future<AsyncResult<List<MovieModel>>> trending({int limit = 20}) {
    return _movieList(ApiConstants.moviesTrending, limit);
  }

  /// Returns `Success(null)` on 404 — backend signals "no trailer available"
  /// that way and the dialog renders an empty state.
  Future<AsyncResult<String?>> trailerKey(int movieId) {
    return runCatching<String?>(() async {
      final http.Response res =
          await _api.get(Uri.parse(ApiConstants.movieTrailer(movieId)));
      if (res.statusCode == 404) return null;
      ApiClient.ensureOk(res);
      final Map<String, dynamic> data =
          jsonDecode(res.body) as Map<String, dynamic>;
      return data['youtube_key'] as String?;
    });
  }

  Future<AsyncResult<List<MovieModel>>> _movieList(String endpoint, int limit) {
    return runCatching<List<MovieModel>>(() async {
      final http.Response res = await _api.get(
        Uri.parse(endpoint).replace(
          queryParameters: <String, String>{'limit': limit.toString()},
        ),
      );
      ApiClient.ensureOk(res);
      final List<dynamic> rows = jsonDecode(res.body) as List<dynamic>;
      return rows
          .map((dynamic m) => MovieModel.fromMap(m as Map<String, dynamic>))
          .toList();
    });
  }
}
