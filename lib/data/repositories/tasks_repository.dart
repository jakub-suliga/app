// lib/data/repositories/tasks_repository.dart

import '../data_providers/tasks_data_provider.dart';
import '../models/task_model.dart';

class TasksRepository {
  final TasksDataProvider dataProvider;

  TasksRepository({required this.dataProvider});

  Future<List<TaskModel>> getTasks() async {
    return await dataProvider.fetchTasks();
  }

  Future<void> addTask(TaskModel task) async {
    await dataProvider.addTask(task);
  }

  Future<void> updateTask(TaskModel updatedTask) async {
    await dataProvider.updateTask(updatedTask);
  }

  Future<void> removeTask(String taskId) async {
    await dataProvider.removeTask(taskId);
  }

  /// Methode zum Markieren einer Aufgabe als abgeschlossen
  Future<void> markTaskAsCompleted(String taskId) async {
    await dataProvider.markTaskAsCompleted(taskId);
  }

  /// Methode zum Wiederherstellen einer abgeschlossenen Aufgabe
  Future<void> restoreTask(String taskId) async {
    await dataProvider.restoreTask(taskId);
  }
}
