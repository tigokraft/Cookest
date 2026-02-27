import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

// State definitions
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final AuthTokens data; // Token pair
  const AuthSuccess(this.data);
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// Controller using Notifier (Riverpod 2.0+)
class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    return const AuthInitial();
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final response = await _repository.login(email, password);
      state = AuthSuccess(response);
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }
  
  Future<void> register(String email, String password) async {
    state = const AuthLoading();
    try {
      final response = await _repository.register(email, password);
      state = AuthSuccess(response); 
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void reset() {
    state = const AuthInitial();
  }
}

// Provider
final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);
