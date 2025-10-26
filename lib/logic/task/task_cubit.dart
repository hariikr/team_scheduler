import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/task_service.dart';
import 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final TaskService _taskService;

  TaskCubit(SupabaseClient supabaseClient)
      : _taskService = TaskService(supabaseClient),
        super(TaskInitial());

  /// Load all tasks
  Future<void> loadTasks() async {
    try {
      emit(TaskLoading());
      final tasks = await _taskService.fetchTasks();
      emit(TaskListLoaded(tasks));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  /// Load a specific task with its collaborators
  Future<void> loadTaskDetail(String taskId) async {
    try {
      emit(TaskLoading());
      final task = await _taskService.fetchTaskById(taskId);
      final collaborators = await _taskService.fetchTaskCollaborators(taskId);
      emit(TaskDetailLoaded(task: task, collaborators: collaborators));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  /// Load all users for collaborator selection
  Future<void> loadUsers() async {
    try {
      emit(TaskLoading());
      final users = await _taskService.fetchUsers();
      emit(UsersLoaded(users));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  /// Find available slots for selected users and duration
  Future<void> findAvailableSlots({
    required List<String> userIds,
    required int durationMinutes,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      emit(TaskLoading());
      final slots = await _taskService.findAvailableSlots(
        userIds: userIds,
        durationMinutes: durationMinutes,
        startDate: startDate,
        endDate: endDate,
      );
      emit(AvailableSlotsLoaded(
        slots: slots,
        durationMinutes: durationMinutes,
      ));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  /// Create a new task
  Future<void> createTask({
    required String title,
    String? description,
    required String createdBy,
    required List<String> collaboratorIds,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      emit(TaskLoading());
      final task = await _taskService.createTask(
        title: title,
        description: description,
        createdBy: createdBy,
        collaboratorIds: collaboratorIds,
        startTime: startTime,
        endTime: endTime,
      );
      emit(TaskCreated(task));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  /// Update an existing task
  Future<void> updateTask({
    required String taskId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      emit(TaskLoading());
      final task = await _taskService.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
      );
      emit(TaskUpdated(task));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      emit(TaskLoading());
      await _taskService.deleteTask(taskId);
      emit(TaskDeleted(taskId));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }
}
