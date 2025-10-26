import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../models/time_slot_model.dart';
import '../models/availability_model.dart';
import '../models/user_model.dart';

class TaskService {
  final SupabaseClient _supabase;

  TaskService(this._supabase);

  /// Fetch all tasks for the current organization
  Future<List<TaskModel>> fetchTasks() async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('*, task_collaborators(users(*))')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TaskModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  /// Fetch tasks where the user is a collaborator
  Future<List<TaskModel>> fetchTasksForCollaborator(String userId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('*, task_collaborators!inner(users(*))')
          .eq('task_collaborators.user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TaskModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch collaborator tasks: $e');
    }
  }

  /// Fetch tasks created by the user
  Future<List<TaskModel>> fetchTasksCreatedBy(String userId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('*, task_collaborators(users(*))')
          .eq('created_by', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TaskModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch created tasks: $e');
    }
  }

  /// Fetch a single task by ID
  Future<TaskModel> fetchTaskById(String taskId) async {
    try {
      final response =
          await _supabase.from('tasks').select().eq('id', taskId).single();

      return TaskModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch task: $e');
    }
  }

  /// Fetch all users in the organization (for collaborator selection)
  Future<List<UserModel>> fetchUsers() async {
    try {
      final response = await _supabase.from('users').select();

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Fetch collaborators for a specific task
  Future<List<UserModel>> fetchTaskCollaborators(String taskId) async {
    try {
      final response = await _supabase
          .from('task_collaborators')
          .select('user_id, users(*)')
          .eq('task_id', taskId);

      return (response as List)
          .map((json) => UserModel.fromJson(json['users']))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch task collaborators: $e');
    }
  }

  /// Find available time slots for given users and duration
  /// This is the core slot-finding algorithm
  Future<List<TimeSlotModel>> findAvailableSlots({
    required List<String> userIds,
    required int durationMinutes,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Default to next 7 days if no date range specified
      final searchStart = startDate ?? DateTime.now();
      final searchEnd = endDate ?? DateTime.now().add(const Duration(days: 7));

      // Fetch availability for all selected users
      final availabilityResponse = await _supabase
          .from('availability')
          .select()
          .inFilter('user_id', userIds)
          .gte('start_time', searchStart.toIso8601String())
          .lte('end_time', searchEnd.toIso8601String());

      List<AvailabilityModel> allAvailability = (availabilityResponse as List)
          .map((json) => AvailabilityModel.fromJson(json))
          .toList();

      // Fetch existing tasks for all users to exclude busy times
      final tasksResponse = await _supabase
          .from('task_collaborators')
          .select('task_id, tasks(*)')
          .inFilter('user_id', userIds);

      List<TaskModel> existingTasks = [];
      for (var item in tasksResponse as List) {
        if (item['tasks'] != null) {
          final task = TaskModel.fromJson(item['tasks']);
          // Only consider scheduled tasks
          if (task.startTime != null && task.endTime != null) {
            existingTasks.add(task);
          }
        }
      }

      // Group availability by user
      Map<String, List<AvailabilityModel>> availabilityByUser = {};
      for (var userId in userIds) {
        availabilityByUser[userId] =
            allAvailability.where((a) => a.userId == userId).toList();
      }

      // Find overlapping time slots
      List<TimeSlotModel> commonSlots = _findCommonSlots(
        availabilityByUser,
        userIds,
        durationMinutes,
        existingTasks,
      );

      return commonSlots;
    } catch (e) {
      throw Exception('Failed to find available slots: $e');
    }
  }

  /// Algorithm to find common available slots
  List<TimeSlotModel> _findCommonSlots(
    Map<String, List<AvailabilityModel>> availabilityByUser,
    List<String> userIds,
    int durationMinutes,
    List<TaskModel> existingTasks,
  ) {
    if (userIds.isEmpty) return [];

    // Get all time intervals from the first user
    List<AvailabilityModel> baseSlots = availabilityByUser[userIds[0]] ?? [];
    if (baseSlots.isEmpty) return [];

    List<TimeSlotModel> commonSlots = [];

    // For each availability slot of the first user
    for (var baseSlot in baseSlots) {
      // Find the intersection with all other users' availability
      DateTime commonStart = baseSlot.startTime;
      DateTime commonEnd = baseSlot.endTime;

      bool isCommon = true;

      // Check intersection with each other user
      for (var userId in userIds.skip(1)) {
        List<AvailabilityModel> userSlots = availabilityByUser[userId] ?? [];

        // Find if this user has any overlapping availability
        bool hasOverlap = false;
        for (var userSlot in userSlots) {
          // Calculate intersection
          DateTime overlapStart = commonStart.isAfter(userSlot.startTime)
              ? commonStart
              : userSlot.startTime;
          DateTime overlapEnd = commonEnd.isBefore(userSlot.endTime)
              ? commonEnd
              : userSlot.endTime;

          if (overlapStart.isBefore(overlapEnd)) {
            hasOverlap = true;
            commonStart = overlapStart;
            commonEnd = overlapEnd;
            break;
          }
        }

        if (!hasOverlap) {
          isCommon = false;
          break;
        }
      }

      if (isCommon) {
        // Split the common slot into chunks of the requested duration
        // excluding existing task times
        List<TimeSlotModel> chunks = _splitIntoChunks(
          commonStart,
          commonEnd,
          durationMinutes,
          existingTasks,
        );
        commonSlots.addAll(chunks);
      }
    }

    // Sort by start time
    commonSlots.sort((a, b) => a.startTime.compareTo(b.startTime));

    return commonSlots;
  }

  /// Split a time range into chunks of specified duration, excluding busy times
  List<TimeSlotModel> _splitIntoChunks(
    DateTime start,
    DateTime end,
    int durationMinutes,
    List<TaskModel> existingTasks,
  ) {
    List<TimeSlotModel> chunks = [];
    DateTime currentStart = start;

    while (currentStart
        .add(Duration(minutes: durationMinutes))
        .isBefore(end.add(const Duration(seconds: 1)))) {
      DateTime currentEnd =
          currentStart.add(Duration(minutes: durationMinutes));

      // Check if this chunk overlaps with any existing task
      bool isAvailable = true;
      for (var task in existingTasks) {
        if (task.startTime != null && task.endTime != null) {
          // Check for overlap
          if (currentStart.isBefore(task.endTime!) &&
              currentEnd.isAfter(task.startTime!)) {
            isAvailable = false;
            // Jump to after this task
            currentStart = task.endTime!;
            break;
          }
        }
      }

      if (isAvailable) {
        chunks.add(TimeSlotModel(
          startTime: currentStart,
          endTime: currentEnd,
        ));
        // Move to next potential slot (with 5-minute buffer)
        currentStart = currentEnd.add(const Duration(minutes: 5));
      }
    }

    return chunks;
  }

  /// Create a new task with collaborators
  Future<TaskModel> createTask({
    required String title,
    String? description,
    required String createdBy,
    required List<String> collaboratorIds,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      // Insert task
      final taskResponse = await _supabase
          .from('tasks')
          .insert({
            'title': title,
            'description': description,
            'created_by': createdBy,
            'start_time': startTime?.toIso8601String(),
            'end_time': endTime?.toIso8601String(),
          })
          .select()
          .single();

      final task = TaskModel.fromJson(taskResponse);

      // Insert collaborators
      if (collaboratorIds.isNotEmpty) {
        final collaborators = collaboratorIds
            .map((userId) => {
                  'task_id': task.id,
                  'user_id': userId,
                })
            .toList();

        await _supabase.from('task_collaborators').insert(collaborators);
      }

      return task;
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  /// Update an existing task
  Future<TaskModel> updateTask({
    required String taskId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (startTime != null) {
        updateData['start_time'] = startTime.toIso8601String();
      }
      if (endTime != null) updateData['end_time'] = endTime.toIso8601String();

      final response = await _supabase
          .from('tasks')
          .update(updateData)
          .eq('id', taskId)
          .select()
          .single();

      return TaskModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      // Collaborators will be deleted automatically due to CASCADE
      await _supabase.from('tasks').delete().eq('id', taskId);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }
}
