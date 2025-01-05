// lib/data/models/task_model.dart

class TaskModel {
  final String id;
  final String title;
  final String description; // Hinzugefügt
  final String priority;
  final DateTime? endDate;
  final Duration duration;
  final bool isCompleted;

  TaskModel({
    required this.id,
    required this.title,
    required this.description, // Hinzugefügt
    required this.priority,
    this.endDate,
    this.duration = const Duration(minutes: 25),
    this.isCompleted = false,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description, // Hinzugefügt
    String? priority,
    DateTime? endDate,
    Duration? duration,
    bool? isCompleted,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description, // Hinzugefügt
      priority: priority ?? this.priority,
      endDate: endDate ?? this.endDate,
      duration: duration ?? this.duration,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '', // Hinzugefügt
      priority: json['priority'],
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      duration: Duration(minutes: json['duration'] ?? 25),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description, // Hinzugefügt
      'priority': priority,
      'endDate': endDate?.toIso8601String(),
      'duration': duration.inMinutes,
      'isCompleted': isCompleted,
    };
  }
}
