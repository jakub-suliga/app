// lib/data/data_providers/tasks_data_provider.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task_model.dart';

class TasksDataProvider {
  final String _tasksKey = 'tasks';

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

  Future<void> addTask(TaskModel task) async {
    final tasks = await fetchTasks();
    tasks.add(task);
    await _saveTasks(tasks);
  }

  Future<void> updateTask(TaskModel updatedTask) async {
    final tasks = await fetchTasks();
    final index = tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      tasks[index] = updatedTask;
      await _saveTasks(tasks);
    }
  }

  Future<void> removeTask(String taskId) async {
    final tasks = await fetchTasks();
    tasks.removeWhere((task) => task.id == taskId);
    await _saveTasks(tasks);
  }

  /// Methode zum Markieren einer Aufgabe als abgeschlossen
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

  /// Methode zum Wiederherstellen einer abgeschlossenen Aufgabe
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

  Future<void> _saveTasks(List<TaskModel> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonData =
        tasks.map((task) => task.toJson()).toList();
    await prefs.setString(_tasksKey, json.encode(jsonData));
  }
}
