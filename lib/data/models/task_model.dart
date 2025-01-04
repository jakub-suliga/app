// lib/data/models/task_model.dart

import 'package:equatable/equatable.dart';

class TaskModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime? endDate;
  final String priority; // Muss nur auf die fixierten Prioritäten beschränkt sein
  final Duration duration;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    this.endDate,
    required this.priority,
    required this.duration,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? endDate,
    String? priority,
    Duration? duration,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      endDate: endDate ?? this.endDate,
      priority: priority ?? this.priority,
      duration: duration ?? this.duration,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        endDate,
        priority,
        duration,
      ];
}
