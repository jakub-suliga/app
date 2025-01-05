import '../data_providers/tasks_data_provider.dart';
import '../models/task_model.dart';

/// Verwaltet das Laden, Hinzufügen, Aktualisieren und Entfernen von Aufgaben.
class TasksRepository {
  final TasksDataProvider dataProvider;

  TasksRepository({required this.dataProvider});

  /// Gibt alle Aufgaben aus dem DataProvider zurück.
  Future<List<TaskModel>> getTasks() async {
    return await dataProvider.fetchTasks();
  }

  /// Fügt eine neue Aufgabe hinzu.
  Future<void> addTask(TaskModel task) async {
    await dataProvider.addTask(task);
  }

  /// Aktualisiert eine vorhandene Aufgabe.
  Future<void> updateTask(TaskModel updatedTask) async {
    await dataProvider.updateTask(updatedTask);
  }

  /// Entfernt eine Aufgabe vollständig.
  Future<void> removeTask(String taskId) async {
    await dataProvider.removeTask(taskId);
  }

  /// Markiert eine Aufgabe als abgeschlossen.
  Future<void> markTaskAsCompleted(String taskId) async {
    await dataProvider.markTaskAsCompleted(taskId);
  }

  /// Stellt eine zuvor abgeschlossene Aufgabe wieder her.
  Future<void> restoreTask(String taskId) async {
    await dataProvider.restoreTask(taskId);
  }
}
