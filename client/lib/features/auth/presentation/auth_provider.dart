import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/models.dart';

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  // 注意：实际通过 getIt 注入，这里仅用于类型定义
  throw UnimplementedError('Use getIt<AuthRepository>() instead');
});

class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final String? error;
  final User? user;

  const AuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.error,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    String? error,
    User? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      error: error,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final isLoggedIn = await _repository.isLoggedIn();
      state = state.copyWith(isLoading: false, isLoggedIn: isLoggedIn);
    } catch (e) {
      state = state.copyWith(isLoading: false, isLoggedIn: false);
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.login(username, password);
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        user: User(id: response.userId, username: response.username),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _repository.register(username, password);
      state = state.copyWith(
        isLoading: false,
        isLoggedIn: true,
        user: User(id: response.userId, username: response.username),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(isLoggedIn: false);
  }
}