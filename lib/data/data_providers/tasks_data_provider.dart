import '../models/task_model.dart';

class TasksDataProvider {
  final List<TaskModel> _tasks = [];

  Future<List<TaskModel>> loadTasks() async => _tasks;

  Future<void> saveTask(TaskModel task) async {
    _tasks.add(task);
  }

  Future<void> deleteTask(TaskModel task) async {
    _tasks.removeWhere((t) => t.id == task.id);
  }

  Future<void> updateTask(TaskModel task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = task;
    }
  }
}
