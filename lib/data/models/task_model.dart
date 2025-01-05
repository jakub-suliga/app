// lib/data/models/task_model.dart

class TaskModel {
  final String id;
  final String title;
  final String description; // Neues Feld
  final String priority;
  final Duration duration;
  final DateTime? endDate;
  final bool isCompleted; // Bereits vorhanden

  TaskModel({
    required this.id,
    required this.title,
    required this.description, // Initialisierung des neuen Feldes
    required this.priority,
    required this.duration,
    this.endDate,
    this.isCompleted = false,
  });

  // Methode zum Kopieren mit Änderungen
  TaskModel copyWith({
    String? id,
    String? title,
    String? description, // Optionales Feld
    String? priority,
    Duration? duration,
    DateTime? endDate,
    bool? isCompleted,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      duration: duration ?? this.duration,
      endDate: endDate ?? this.endDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // JSON-Serialisierung
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      priority: json['priority'],
      duration: Duration(minutes: json['duration']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'duration': duration.inMinutes,
      'endDate': endDate?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
}
