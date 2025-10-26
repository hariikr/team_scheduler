import 'package:equatable/equatable.dart';
import 'user_model.dart';

class TaskModel extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String createdBy;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime createdAt;
  final List<UserModel>? collaborators;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.createdBy,
    this.startTime,
    this.endTime,
    required this.createdAt,
    this.collaborators,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    List<UserModel>? collaborators;
    if (json['task_collaborators'] != null) {
      collaborators = (json['task_collaborators'] as List)
          .map((collab) => UserModel.fromJson(collab['users']))
          .toList();
    }

    return TaskModel(
      id: json['id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      collaborators: collaborators,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_by': createdBy,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
    List<UserModel>? collaborators,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      collaborators: collaborators ?? this.collaborators,
    );
  }

  int get durationInMinutes {
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!).inMinutes;
    }
    return 0;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        createdBy,
        startTime,
        endTime,
        createdAt,
        collaborators,
      ];
}
