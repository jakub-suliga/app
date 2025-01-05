// lib/logic/tasks/tasks_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/task_model.dart';
import '../../data/repositories/tasks_repository.dart';

part 'tasks_state.dart';

/// Steuert das Laden, Hinzufügen, Aktualisieren und Löschen von Aufgaben.
class TasksCubit extends Cubit<TasksState> {
  final TasksRepository tasksRepository;

  TasksCubit({required this.tasksRepository}) : super(TasksInitial()) {
    loadTasks();
  }

  /// Lädt alle vorhandenen Aufgaben aus dem Repository.
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

  /// Fügt eine neue Aufgabe hinzu.
  Future<void> addTask(TaskModel task) async {
    try {
      await tasksRepository.addTask(task);
      loadTasks();
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  /// Aktualisiert eine vorhandene Aufgabe.
  Future<void> updateTask(TaskModel updatedTask) async {
    try {
      await tasksRepository.updateTask(updatedTask);
      loadTasks();
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  /// Markiert eine Aufgabe als erledigt.
  Future<void> markTaskAsCompleted(String taskId) async {
    try {
      await tasksRepository.markTaskAsCompleted(taskId);
      loadTasks();
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  /// Stellt eine erledigte Aufgabe wieder her.
  Future<void> restoreTask(String taskId) async {
    try {
      await tasksRepository.restoreTask(taskId);
      loadTasks();
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  /// Entfernt eine Aufgabe endgültig.
  Future<void> removeTask(String taskId) async {
    try {
      await tasksRepository.removeTask(taskId);
      loadTasks();
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  /// Gibt die nächste Aufgabe basierend auf Priorität und Fälligkeitsdatum zurück.
  TaskModel? getNextTask() {
    if (state is TasksLoaded) {
      final activeTasks = (state as TasksLoaded).activeTasks;
      if (activeTasks.isNotEmpty) {
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

  /// Übersetzt eine Prioritätsangabe in eine Ordnungszahl.
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
