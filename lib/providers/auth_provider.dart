import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final supabase.User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    supabase.User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  StreamSubscription<supabase.AuthState>? _authSubscription;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _init();
  }

  void _init() {
    _authSubscription = _authService.authStateChanges.listen((authState) {
      final user = authState.session?.user;
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
        );
      }
    });

    // Check initial session
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: currentUser,
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: response.user,
        );
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Registration failed',
        );
      }
    } on supabase.AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _translateAuthError(e.message),
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );
      if (response.user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: response.user,
        );
      }
    } on supabase.AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _translateAuthError(e.message),
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _authService.signInWithGoogle();
      if (response.user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: response.user,
        );
      }
    } on supabase.AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _translateAuthError(e.message),
      );
    } catch (e) {
      final message = e.toString();
      if (message.contains('cancelled')) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      } else {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: message,
        );
      }
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
    );
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authService.resetPassword(email);
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } on supabase.AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _translateAuthError(e.message),
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  String _translateAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'メールアドレスまたはパスワードが正しくありません';
    }
    if (message.contains('Email not confirmed')) {
      return 'メールアドレスの確認が完了していません';
    }
    if (message.contains('User already registered')) {
      return 'このメールアドレスは既に登録されています';
    }
    if (message.contains('Password should be at least')) {
      return 'パスワードは6文字以上で入力してください';
    }
    if (message.contains('Unable to validate email')) {
      return 'メールアドレスの形式が正しくありません';
    }
    return message;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
