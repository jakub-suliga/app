// lib/data/repositories/tasks_repository.dart

import '../data_providers/tasks_data_provider.dart';
import '../models/task_model.dart';

class TasksRepository {
  final TasksDataProvider dataProvider;

  TasksRepository({required this.dataProvider});

  Future<List<TaskModel>> getAllTasks() => dataProvider.loadTasks();
  Future<void> addTask(TaskModel task) => dataProvider.saveTask(task);
  Future<void> removeTask(TaskModel task) => dataProvider.deleteTask(task);
  Future<void> updateTask(TaskModel task) => dataProvider.updateTask(task);
}
