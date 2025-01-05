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

  Future<void> updateTask(TaskModel task) async {
    await dataProvider.updateTask(task);
  }

  Future<void> removeTask(String taskId) async {
    await dataProvider.removeTask(taskId);
  }
}
