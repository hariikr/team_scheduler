import 'package:equatable/equatable.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/time_slot_model.dart';

abstract class TaskState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {}

class TaskLoading extends TaskState {}

class TaskListLoaded extends TaskState {
  final List<TaskModel> tasks;

  TaskListLoaded(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class TaskDetailLoaded extends TaskState {
  final TaskModel task;
  final List<UserModel> collaborators;

  TaskDetailLoaded({
    required this.task,
    required this.collaborators,
  });

  @override
  List<Object?> get props => [task, collaborators];
}

class UsersLoaded extends TaskState {
  final List<UserModel> users;

  UsersLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class AvailableSlotsLoaded extends TaskState {
  final List<TimeSlotModel> slots;
  final int durationMinutes;

  AvailableSlotsLoaded({
    required this.slots,
    required this.durationMinutes,
  });

  @override
  List<Object?> get props => [slots, durationMinutes];
}

class TaskCreated extends TaskState {
  final TaskModel task;

  TaskCreated(this.task);

  @override
  List<Object?> get props => [task];
}

class TaskUpdated extends TaskState {
  final TaskModel task;

  TaskUpdated(this.task);

  @override
  List<Object?> get props => [task];
}

class TaskDeleted extends TaskState {
  final String taskId;

  TaskDeleted(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class TaskError extends TaskState {
  final String message;

  TaskError(this.message);

  @override
  List<Object?> get props => [message];
}
