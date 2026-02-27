import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/storage/secure_storage.dart';

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(ref.read(apiClientProvider)),
);

class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );
}

class AuthRepository {
  final ApiClient _api;
  AuthRepository(this._api);

  Future<AuthTokens> login(String email, String password) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final tokens = AuthTokens.fromJson(data);
    await SecureStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return tokens;
  }

  Future<AuthTokens> register(String email, String password) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'email': email, 'password': password},
    );
    final tokens = AuthTokens.fromJson(data);
    await SecureStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return tokens;
  }

  Future<void> logout() async {
    try {
      await _api.post<void>('/auth/logout', data: {});
    } catch (_) {}
    await SecureStorage.clearTokens();
  }

  Future<bool> hasValidSession() async {
    final token = await SecureStorage.getAccessToken();
    return token != null;
  }
}

// ── Auth state ────────────────────────────────────────────────────────────────

sealed class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// ── Auth notifier ─────────────────────────────────────────────────────────────

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(AuthInitial()) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    final valid = await _repo.hasValidSession();
    state = valid ? AuthAuthenticated() : AuthUnauthenticated();
  }

  Future<void> login(String email, String password) async {
    state = AuthLoading();
    try {
      await _repo.login(email, password);
      state = AuthAuthenticated();
    } on AppError catch (e) {
      state = AuthError(e.message);
    } catch (_) {
      state = AuthError('Network error. Is the server running?');
    }
  }

  Future<void> register(String email, String password) async {
    state = AuthLoading();
    try {
      await _repo.register(email, password);
      state = AuthAuthenticated();
    } on AppError catch (e) {
      state = AuthError(e.message);
    } catch (_) {
      state = AuthError('Network error. Is the server running?');
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = AuthUnauthenticated();
  }
}
