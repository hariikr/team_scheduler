import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase;
  final Uuid _uuid = const Uuid();

  AuthService(this._supabase);

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    File? profileImage,
  }) async {
    try {
      // Sign up with Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create account');
      }

      String? photoUrl;

      // Upload profile image if provided
      if (profileImage != null) {
        final fileExt = profileImage.path.split('.').last;
        final fileName = '${_uuid.v4()}.$fileExt';
        final filePath = fileName;

        await _supabase.storage.from('profile').upload(filePath, profileImage);
        photoUrl = _supabase.storage.from('profile').getPublicUrl(filePath);
      }

      // Create user profile in the users table
      final response = await _supabase
          .from('users')
          .insert({
            'id': authResponse.user!.id,
            'email': email,
            'name': name,
            'photo_url': photoUrl,
          })
          .select()
          .single();

      return UserModel.fromJson(response);
    } on AuthException catch (e) {
      throw Exception('Authentication error: ${e.message}');
    } on StorageException catch (e) {
      throw Exception('Failed to upload image: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to sign in');
      }

      // Fetch user profile from database
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', authResponse.user!.id)
          .single();

      return UserModel.fromJson(response);
    } on AuthException catch (e) {
      throw Exception('Authentication error: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw Exception('Sign out error: ${e.message}');
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final response =
          await _supabase.from('users').select().eq('id', user.id).single();

      return UserModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch user profile: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    required String userId,
    String? name,
    File? profileImage,
  }) async {
    try {
      String? photoUrl;

      // Upload new profile image if provided
      if (profileImage != null) {
        final fileExt = profileImage.path.split('.').last;
        final fileName = '${_uuid.v4()}.$fileExt';
        final filePath = fileName;

        await _supabase.storage.from('profile').upload(filePath, profileImage);
        photoUrl = _supabase.storage.from('profile').getPublicUrl(filePath);
      }

      // Update user profile in database
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (photoUrl != null) updateData['photo_url'] = photoUrl;

      final response = await _supabase
          .from('users')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      return UserModel.fromJson(response);
    } on StorageException catch (e) {
      throw Exception('Failed to upload image: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('Failed to update profile: ${e.message}');
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }

  /// Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception('Password reset error: ${e.message}');
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }
}
