import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  const TaskTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(task.title),
      subtitle: Text(
        'Fällig: ${task.dueDate?.toIso8601String() ?? "Kein Datum"} '
        ' | Priorität: ${task.priority}',
      ),
    );
  }
}
