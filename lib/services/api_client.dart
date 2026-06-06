import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:movie_recommender_web/core/exceptions/app_exception.dart';
import 'package:pretty_http_logger/pretty_http_logger.dart';

/// Shared HTTP plumbing used by every feature service.
///
/// Each feature service holds its own [ApiClient] but reuses the same
/// auth-header callback supplied by the caller, so a single login powers
/// every request across all services.
class ApiClient {
  ApiClient({required Map<String, String> Function() getHeaders})
      : _getHeaders = getHeaders;

  final http.Client _client = HttpClientWithMiddleware.build(
    middlewares: [HttpLogger(logLevel: LogLevel.BODY)],
  );
  final Map<String, String> Function() _getHeaders;

  Future<http.Response> get(Uri uri) => _client.get(uri, headers: _getHeaders());

  Future<http.Response> post(Uri uri, {Object? body}) => _client.post(
        uri,
        headers: _getHeaders(),
        body: body == null ? null : jsonEncode(body),
      );

  Future<http.Response> put(Uri uri, {Object? body}) => _client.put(
        uri,
        headers: _getHeaders(),
        body: body == null ? null : jsonEncode(body),
      );

  Future<http.Response> delete(Uri uri) =>
      _client.delete(uri, headers: _getHeaders());

  /// Throw an [AppException] when [response] is not a 2xx.
  static void ensureOk(http.Response response) {
    final int s = response.statusCode;
    if (s >= 200 && s < 300) return;
    throw AppException.fromStatusCode(s, parseErrorBody(response.body));
  }

  /// Parse FastAPI's `{"detail": ...}` body to a friendly message. Returns
  /// `null` when the body is empty / not JSON so the caller falls back to a
  /// generic status-code message.
  static String? parseErrorBody(String body) {
    if (body.isEmpty) return null;
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final dynamic detail = decoded['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final dynamic first = detail.first;
        if (first is Map<String, dynamic>) {
          final String msg = first['msg'] as String? ?? '';
          final List<dynamic>? loc = first['loc'] as List<dynamic>?;
          final String field =
              (loc != null && loc.length > 1) ? loc.last.toString() : '';
          return field.isNotEmpty ? '$field: $msg' : msg;
        }
      }
      return decoded['message'] as String?;
    } catch (_) {
      return null;
    }
  }
}
