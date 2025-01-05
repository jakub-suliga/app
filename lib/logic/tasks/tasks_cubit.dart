// lib/logic/tasks/tasks_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/tasks_repository.dart';

part 'tasks_state.dart';

class TasksCubit extends Cubit<TasksState> {
  final TasksRepository tasksRepository;

  TasksCubit({required this.tasksRepository}) : super(TasksInitial()) {
    loadTasks();
  }

  /// Lädt alle Aufgaben und trennt sie in aktive und erledigte Aufgaben
  Future<void> loadTasks() async {
    emit(TasksLoading());
    try {
      final tasks = await tasksRepository.getTasks();
      final activeTasks = tasks.where((task) => !task.isCompleted).toList();
      final completedTasks = tasks.where((task) => task.isCompleted).toList();
      emit(TasksLoaded(activeTasks: activeTasks, completedTasks: completedTasks));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  /// Fügt eine neue Aufgabe hinzu
  Future<void> addTask(TaskModel task) async {
    try {
      await tasksRepository.addTask(task);
      loadTasks();
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  /// Aktualisiert eine bestehende Aufgabe
  Future<void> updateTask(TaskModel updatedTask) async {
    try {
      await tasksRepository.updateTask(updatedTask);
      loadTasks();
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  /// Markiert eine Aufgabe als abgeschlossen
  Future<void> markTaskAsCompleted(String taskId) async {
    try {
      final tasks = await tasksRepository.getTasks();
      final task = tasks.firstWhere((task) => task.id == taskId);
      final updatedTask = task.copyWith(isCompleted: true);
      await tasksRepository.updateTask(updatedTask);
      loadTasks();
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  /// Stellt eine erledigte Aufgabe wieder her
  Future<void> restoreTask(String taskId) async {
    try {
      final tasks = await tasksRepository.getTasks();
      final task = tasks.firstWhere((task) => task.id == taskId);
      final updatedTask = task.copyWith(isCompleted: false);
      await tasksRepository.updateTask(updatedTask);
      loadTasks();
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  /// Entfernt eine Aufgabe vollständig
  Future<void> removeTask(String taskId) async {
    try {
      await tasksRepository.removeTask(taskId);
      loadTasks();
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  /// Gibt die nächste aktive Aufgabe zurück (z.B. nach Priorität sortiert)
  TaskModel? getNextTask() {
    if (state is TasksLoaded) {
      final activeTasks = (state as TasksLoaded).activeTasks;
      if (activeTasks.isNotEmpty) {
        // Beispiel: Sortiere nach Priorität und Fälligkeitsdatum
        activeTasks.sort((a, b) {
          int priorityComparison = _priorityValue(a.priority).compareTo(_priorityValue(b.priority));
          if (priorityComparison != 0) return priorityComparison;
          if (a.endDate != null && b.endDate != null) {
            return a.endDate!.compareTo(b.endDate!);
          } else if (a.endDate != null) {
            return -1;
          } else if (b.endDate != null) {
            return 1;
          }
          return 0;
        });
        return activeTasks.first;
      }
    }
    return null;
  }

  /// Hilfsmethode zur Prioritätsbewertung
  int _priorityValue(String priority) {
    switch (priority.toLowerCase()) {
      case 'hoch':
        return 1;
      case 'mittel':
        return 2;
      case 'niedrig':
        return 3;
      default:
        return 4;
    }
  }
}
