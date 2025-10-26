import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'availability_state.dart';
import '../../data/models/availability_model.dart';

class AvailabilityCubit extends Cubit<AvailabilityState> {
  final SupabaseClient _supabase;
  final String userId;

  AvailabilityCubit(this._supabase, this.userId)
      : super(const AvailabilityInitial());

  /// Load all availability slots for the user
  Future<void> loadAvailability() async {
    try {
      emit(const AvailabilityLoading());

      final response = await _supabase
          .from('availability')
          .select()
          .eq('user_id', userId)
          .order('start_time', ascending: true);

      final slots = (response as List)
          .map((json) => AvailabilityModel.fromJson(json))
          .toList();

      emit(AvailabilityLoaded(slots));
    } on PostgrestException catch (e) {
      emit(AvailabilityError('Failed to load availability: ${e.message}'));
    } catch (e) {
      emit(AvailabilityError('An unexpected error occurred: $e'));
    }
  }

  /// Add a new availability slot
  Future<void> addSlot({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      // Validate the time range
      if (startTime.isAfter(endTime) || startTime.isAtSameMomentAs(endTime)) {
        emit(const AvailabilityError('Start time must be before end time'));
        return;
      }

      emit(const AvailabilityLoading());

      await _supabase.from('availability').insert({
        'user_id': userId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
      });

      // Reload availability after adding
      await _loadSlotsQuietly();
    } on PostgrestException catch (e) {
      emit(AvailabilityError('Failed to add slot: ${e.message}'));
    } catch (e) {
      emit(AvailabilityError('An unexpected error occurred: $e'));
    }
  }

  /// Delete an availability slot
  Future<void> deleteSlot(String slotId) async {
    try {
      emit(const AvailabilityLoading());

      await _supabase.from('availability').delete().eq('id', slotId);

      // Reload availability after deleting
      await _loadSlotsQuietly();
    } on PostgrestException catch (e) {
      emit(AvailabilityError('Failed to delete slot: ${e.message}'));
    } catch (e) {
      emit(AvailabilityError('An unexpected error occurred: $e'));
    }
  }

  /// Update an availability slot
  Future<void> updateSlot({
    required String slotId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      // Validate the time range
      if (startTime.isAfter(endTime) || startTime.isAtSameMomentAs(endTime)) {
        emit(const AvailabilityError('Start time must be before end time'));
        return;
      }

      emit(const AvailabilityLoading());

      await _supabase.from('availability').update({
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
      }).eq('id', slotId);

      // Reload availability after updating
      await _loadSlotsQuietly();
    } on PostgrestException catch (e) {
      emit(AvailabilityError('Failed to update slot: ${e.message}'));
    } catch (e) {
      emit(AvailabilityError('An unexpected error occurred: $e'));
    }
  }

  /// Helper method to reload slots without emitting loading state
  Future<void> _loadSlotsQuietly() async {
    final response = await _supabase
        .from('availability')
        .select()
        .eq('user_id', userId)
        .order('start_time', ascending: true);

    final slots = (response as List)
        .map((json) => AvailabilityModel.fromJson(json))
        .toList();

    emit(AvailabilityLoaded(slots));
  }

  void reset() {
    emit(const AvailabilityInitial());
  }
}
