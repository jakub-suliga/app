/// Repräsentiert eine einzelne Aufgabe mit Titel, Beschreibung, Priorität und Fälligkeitsdatum.
class TaskModel {
  final String id;
  final String title;
  final String description;
  final String priority;
  final DateTime? endDate;
  final Duration duration;
  final bool isCompleted;

  /// Erstellt eine neue Aufgabe mit den gegebenen Eigenschaften.
  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    this.endDate,
    this.duration = const Duration(minutes: 25),
    this.isCompleted = false,
  });

  /// Erzeugt eine Kopie dieser Aufgabe, bei Bedarf mit geänderten Feldern.
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    DateTime? endDate,
    Duration? duration,
    bool? isCompleted,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      endDate: endDate ?? this.endDate,
      duration: duration ?? this.duration,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Erstellt ein TaskModel aus einer JSON-Struktur.
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      priority: json['priority'],
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      duration: Duration(minutes: json['duration'] ?? 25),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  /// Wandelt diese Aufgabe in eine JSON-Struktur um.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'endDate': endDate?.toIso8601String(),
      'duration': duration.inMinutes,
      'isCompleted': isCompleted,
    };
  }
}
