class TaskModel {
  final String id;
  final String title;
  final String description;
  final bool isDone;
  final DateTime? dueDate;
  final Duration? estimatedDuration;
  final int priority;   // 0 = niedrig, 1 = mittel, 2 = hoch
  final List<String> tags;
  final bool repeatDaily;
  final bool repeatWeekly;
  final bool repeatMonthly;

  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.isDone = false,          
    this.dueDate,
    this.estimatedDuration,
    this.priority = 0,
    this.tags = const [],
    this.repeatDaily = false,
    this.repeatWeekly = false,
    this.repeatMonthly = false,
  });

  // Falls du copyWith brauchst
  TaskModel copyWith({
    String? title,
    String? description,
    bool? isDone,
    DateTime? dueDate,
    Duration? estimatedDuration,
    int? priority,
    List<String>? tags,
    bool? repeatDaily,
    bool? repeatWeekly,
    bool? repeatMonthly,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,          // <--
      dueDate: dueDate ?? this.dueDate,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      repeatDaily: repeatDaily ?? this.repeatDaily,
      repeatWeekly: repeatWeekly ?? this.repeatWeekly,
      repeatMonthly: repeatMonthly ?? this.repeatMonthly,
    );
  }
}
