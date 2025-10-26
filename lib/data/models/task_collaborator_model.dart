import 'package:equatable/equatable.dart';

class TaskCollaboratorModel extends Equatable {
  final String id;
  final String taskId;
  final String userId;
  final DateTime createdAt;

  const TaskCollaboratorModel({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.createdAt,
  });

  factory TaskCollaboratorModel.fromJson(Map<String, dynamic> json) {
    return TaskCollaboratorModel(
      id: json['id'].toString(),
      taskId: json['task_id'].toString(),
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, taskId, userId, createdAt];
}
