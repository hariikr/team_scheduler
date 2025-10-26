import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'user_state.dart';
import '../../data/models/user_model.dart';

class UserCubit extends Cubit<UserState> {
  final SupabaseClient _supabase;
  final Uuid _uuid = const Uuid();

  UserCubit(this._supabase) : super(const UserInitial());

  Future<void> fetchUser(String userId) async {
    try {
      emit(const UserLoading());

      final response =
          await _supabase.from('users').select().eq('id', userId).single();

      final user = UserModel.fromJson(response);

      emit(UserSuccess(
        userId: user.id,
        name: user.name,
        photoUrl: user.photoUrl,
      ));
    } on PostgrestException catch (e) {
      emit(UserError('Failed to fetch user: ${e.message}'));
    } catch (e) {
      emit(UserError('An unexpected error occurred: $e'));
    }
  }

  Future<void> createUser({
    required String name,
    File? profileImage,
  }) async {
    try {
      emit(const UserLoading());

      String? photoUrl;

      // Upload profile image to Supabase Storage
      if (profileImage != null) {
        final fileExt = profileImage.path.split('.').last;
        final fileName = '${_uuid.v4()}.$fileExt';
        final filePath = fileName;

        await _supabase.storage.from('profile').upload(filePath, profileImage);

        // Get public URL
        photoUrl = _supabase.storage.from('profile').getPublicUrl(filePath);
      }

      // Insert user data into database
      final response = await _supabase
          .from('users')
          .insert({
            'name': name,
            'photo_url': photoUrl,
          })
          .select()
          .single();

      final user = UserModel.fromJson(response);

      emit(UserSuccess(
        userId: user.id,
        name: user.name,
        photoUrl: user.photoUrl,
      ));
    } on StorageException catch (e) {
      emit(UserError('Failed to upload image: ${e.message}'));
    } on PostgrestException catch (e) {
      emit(UserError('Failed to create user: ${e.message}'));
    } catch (e) {
      emit(UserError('An unexpected error occurred: $e'));
    }
  }

  void reset() {
    emit(const UserInitial());
  }
}
