import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';
import '../../data/services/auth_service.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit(this._authService) : super(const AuthInitial());

  /// Check authentication status on app start
  Future<void> checkAuthStatus() async {
    try {
      emit(const AuthLoading());

      if (_authService.isAuthenticated) {
        final user = await _authService.getCurrentUserProfile();
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    File? profileImage,
  }) async {
    try {
      emit(const AuthLoading());

      final user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        profileImage: profileImage,
      );

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(const AuthUnauthenticated());
    }
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      emit(const AuthLoading());

      final user = await _authService.signIn(
        email: email,
        password: password,
      );

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(const AuthUnauthenticated());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      emit(const AuthLoading());
      await _authService.signOut();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _authService.resetPassword(email: email);
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    required String userId,
    String? name,
    File? profileImage,
  }) async {
    try {
      emit(const AuthLoading());

      final user = await _authService.updateProfile(
        userId: userId,
        name: name,
        profileImage: profileImage,
      );

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
