import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

/// Speichert und verwaltet Aufgaben mithilfe von SharedPreferences.
class TasksDataProvider {
  final String _tasksKey = 'tasks';

  /// Lädt alle Aufgaben aus SharedPreferences.
  Future<List<TaskModel>> fetchTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksString = prefs.getString(_tasksKey);
    if (tasksString != null) {
      final List<dynamic> jsonData = json.decode(tasksString);
      return jsonData.map((e) => TaskModel.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  /// Fügt eine neue Aufgabe hinzu.
  Future<void> addTask(TaskModel task) async {
    final tasks = await fetchTasks();
    tasks.add(task);
    await _saveTasks(tasks);
  }

  /// Aktualisiert eine bestehende Aufgabe anhand ihrer ID.
  Future<void> updateTask(TaskModel updatedTask) async {
    final tasks = await fetchTasks();
    final index = tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      tasks[index] = updatedTask;
      await _saveTasks(tasks);
    }
  }

  /// Entfernt eine Aufgabe vollständig anhand ihrer ID.
  Future<void> removeTask(String taskId) async {
    final tasks = await fetchTasks();
    tasks.removeWhere((task) => task.id == taskId);
    await _saveTasks(tasks);
  }

  /// Markiert eine Aufgabe als abgeschlossen.
  Future<void> markTaskAsCompleted(String taskId) async {
    final tasks = await fetchTasks();
    final taskIndex = tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = tasks[taskIndex];
      final updatedTask = task.copyWith(isCompleted: true);
      tasks[taskIndex] = updatedTask;
      await _saveTasks(tasks);
    } else {
      throw Exception('Task not found');
    }
  }

  /// Macht eine zuvor abgeschlossene Aufgabe wieder aktiv.
  Future<void> restoreTask(String taskId) async {
    final tasks = await fetchTasks();
    final taskIndex = tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final task = tasks[taskIndex];
      final updatedTask = task.copyWith(isCompleted: false);
      tasks[taskIndex] = updatedTask;
      await _saveTasks(tasks);
    } else {
      throw Exception('Task not found');
    }
  }

  /// Speichert alle Aufgaben in SharedPreferences.
  Future<void> _saveTasks(List<TaskModel> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonData =
        tasks.map((task) => task.toJson()).toList();
    await prefs.setString(_tasksKey, json.encode(jsonData));
  }
}
