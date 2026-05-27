import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movie_recommender_web/core/constants/api_constants.dart';
import 'package:movie_recommender_web/core/exceptions/app_exception.dart';
import 'package:movie_recommender_web/core/exceptions/async_result.dart';
import 'package:movie_recommender_web/models/user_model.dart';
import 'package:pretty_http_logger/pretty_http_logger.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';

  final http.Client _client = HttpClientWithMiddleware.build(
    middlewares: [HttpLogger(logLevel: LogLevel.BODY)],
  );

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  String? _token;
  UserModel? _currentUser;

  String? get token => _token;
  UserModel? get currentUser => _currentUser;

  /// Try to restore session from stored token. Returns user if valid.
  Future<AsyncResult<UserModel>> tryRestoreSession() async {
    return runCatching<UserModel>(() async {
      final String? storedToken = await _prefs.getString(_tokenKey);

      if (storedToken == null || storedToken.isEmpty) {
        throw const AppException(message: 'No stored session');
      }

      _token = storedToken;

      // Validate token by fetching current user
      final UserModel user = await _fetchCurrentUser();
      _currentUser = user;
      return user;
    });
  }

  Future<void> _saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  Future<void> _clearToken() async {
    await _prefs.remove(_tokenKey);
  }

  Future<AsyncResult<UserModel>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return runCatching<UserModel>(() async {
      final http.Response response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode != 200) {
        throw AppException.fromStatusCode(
            response.statusCode, _parseError(response.body));
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      _token = data['access_token'] as String?;

      if (_token == null || _token!.isEmpty) {
        throw const AppException(message: 'Login failed. Please try again.');
      }

      await _saveToken(_token!);

      // Fetch user profile with token
      final UserModel user = await _fetchCurrentUser();
      _currentUser = user;
      return user;
    });
  }

  Future<AsyncResult<UserModel>> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    return runCatching<UserModel>(() async {
      final http.Response response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw AppException.fromStatusCode(
            response.statusCode, _parseError(response.body));
      }

      // Auto-login after signup
      final loginResult = await signInWithEmail(email: email, password: password);

      return loginResult.when(
        success: (user) => user,
        failure: (e) => throw e,
      );
    });
  }

  Future<AsyncResult<void>> sendPasswordResetEmail(
      {required String email}) async {
    // Backend doesn't have this endpoint yet — no-op for now
    return runCatching<void>(() async {
      // Placeholder — could be added to backend later
    });
  }

  Future<AsyncResult<UserModel>> updateProfile({
    String? firstName,
    String? lastName,
    int? age,
    String? gender,
  }) async {
    return runCatching<UserModel>(() async {
      final Map<String, dynamic> body = {};
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (age != null) body['age'] = age;
      if (gender != null) body['gender'] = gender;

      final http.Response response = await _client.put(
        Uri.parse('${ApiConstants.baseUrl}/auth/profile'),
        headers: authHeaders,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw AppException.fromStatusCode(
            response.statusCode, _parseError(response.body));
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      final UserModel user = UserModel.fromMap(data);
      _currentUser = user;
      return user;
    });
  }

  Future<AsyncResult<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return runCatching<void>(() async {
      final http.Response response = await _client.put(
        Uri.parse('${ApiConstants.baseUrl}/auth/change-password'),
        headers: authHeaders,
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        throw AppException.fromStatusCode(
            response.statusCode, _parseError(response.body));
      }
    });
  }

  Future<AsyncResult<void>> signOut() async {
    return runCatching<void>(() async {
      _token = null;
      _currentUser = null;
      await _clearToken();
    });
  }

  Future<UserModel> _fetchCurrentUser() async {
    final http.Response response = await _client.get(
      Uri.parse('${ApiConstants.baseUrl}/auth/me'),
      headers: authHeaders,
    );

    if (response.statusCode != 200) {
      _token = null;
      await _clearToken();
      throw AppException.fromStatusCode(
          response.statusCode, _parseError(response.body));
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  String? _parseError(String body) {
    try {
      final Map<String, dynamic> data =
          jsonDecode(body) as Map<String, dynamic>;
      final dynamic detail = data['detail'];

      // FastAPI returns detail as String for HTTPException
      if (detail is String) return detail;

      // FastAPI returns detail as List for validation errors (422)
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map<String, dynamic>) {
          final String msg = first['msg'] as String? ?? '';
          final List? loc = first['loc'] as List?;
          final String field = loc != null && loc.length > 1
              ? loc.last.toString()
              : '';
          return field.isNotEmpty ? '$field: $msg' : msg;
        }
      }

      return data['message'] as String?;
    } catch (_) {
      return null;
    }
  }
}
