// lib/data/models/task_model.dart

import 'package:equatable/equatable.dart';

class TaskModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime? endDate; // Neues Feld für das Enddatum
  final String priority; // Neues Feld für die Priorität
  final Duration duration; // Neues Feld für die Dauer
  final bool isDone; // Status der Aufgabe

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    this.endDate,
    this.priority = 'Normal',
    this.duration = const Duration(minutes: 25),
    this.isDone = false,
  });

  // Optional: Methoden zur Serialisierung/Deserialisierung, falls verwendet
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      priority: map['priority'] ?? 'Normal',
      duration: Duration(minutes: map['duration'] ?? 25),
      isDone: map['isDone'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'endDate': endDate?.toIso8601String(),
      'priority': priority,
      'duration': duration.inMinutes,
      'isDone': isDone,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? endDate,
    String? priority,
    Duration? duration,
    bool? isDone,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      endDate: endDate ?? this.endDate,
      priority: priority ?? this.priority,
      duration: duration ?? this.duration,
      isDone: isDone ?? this.isDone,
    );
  }

  @override
  List<Object?> get props => [id, title, description, endDate, priority, duration, isDone];
}
