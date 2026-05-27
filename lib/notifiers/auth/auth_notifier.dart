import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommender_web/core/exceptions/async_result.dart';
import 'package:movie_recommender_web/models/user_model.dart';
import 'package:movie_recommender_web/notifiers/auth/auth_state.dart';
import 'package:movie_recommender_web/services/auth_service.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState.initial()) {
    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    final AsyncResult<UserModel> result = await _authService.tryRestoreSession();
    result.when(
      success: (UserModel user) => state = AuthState.authenticated(user),
      failure: (_) => state = const AuthState.unauthenticated(),
    );
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthState.loading();

    final AsyncResult<UserModel> result = await _authService.signInWithEmail(
      email: email,
      password: password,
    );

    result.when(
      success: (UserModel user) => state = AuthState.authenticated(user),
      failure: (exception) => state = AuthState.error(exception.message),
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = const AuthState.loading();

    final AsyncResult<UserModel> result = await _authService.registerWithEmail(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );

    result.when(
      success: (UserModel user) => state = AuthState.authenticated(user),
      failure: (exception) => state = AuthState.error(exception.message),
    );
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    state = const AuthState.loading();

    final AsyncResult<void> result = await _authService.sendPasswordResetEmail(
      email: email,
    );

    result.when(
      success: (_) => state = const AuthState.unauthenticated(),
      failure: (exception) => state = AuthState.error(exception.message),
    );
  }

  Future<void> signOut() async {
    state = const AuthState.loading();

    final AsyncResult<void> result = await _authService.signOut();

    result.when(
      success: (_) => state = const AuthState.unauthenticated(),
      failure: (exception) => state = AuthState.error(exception.message),
    );
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    int? age,
    String? gender,
  }) async {
    final AsyncResult<UserModel> result = await _authService.updateProfile(
      firstName: firstName,
      lastName: lastName,
      age: age,
      gender: gender,
    );

    return result.when(
      success: (UserModel user) {
        state = AuthState.authenticated(user);
        return true;
      },
      failure: (exception) {
        state = AuthState.error(exception.message);
        return false;
      },
    );
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final AsyncResult<void> result = await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    return result.when(
      success: (_) => true,
      failure: (exception) {
        state = state.user != null
            ? AuthState(status: AuthStatus.authenticated, user: state.user, errorMessage: exception.message)
            : AuthState.error(exception.message);
        return false;
      },
    );
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      if (state.user != null) {
        state = AuthState.authenticated(state.user!);
      } else {
        state = const AuthState.unauthenticated();
      }
    }
  }
}

final Provider<AuthService> authServiceProvider = Provider<AuthService>(
  (Ref ref) => AuthService(),
);

final StateNotifierProvider<AuthNotifier, AuthState> authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
  (Ref ref) => AuthNotifier(ref.read(authServiceProvider)),
);
