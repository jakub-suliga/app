// lib/logic/tasks/tasks_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/task_model.dart';

abstract class TasksState extends Equatable {
  const TasksState();

  @override
  List<Object> get props => [];
}

class TasksInitial extends TasksState {}

class TasksLoading extends TasksState {}

class TasksLoaded extends TasksState {
  final List<TaskModel> tasks;

  const TasksLoaded(this.tasks);

  @override
  List<Object> get props => [tasks];
}

class TasksError extends TasksState {
  final String message;

  const TasksError(this.message);

  @override
  List<Object> get props => [message];
}

class TasksCubit extends Cubit<TasksState> {
  TasksCubit() : super(TasksInitial());

  List<TaskModel> _tasks = [];

  void loadTasks() {
    emit(TasksLoading());
    try {
      // Hier können Sie Ihre Daten aus einer Datenbank oder einem Service laden
      // Für dieses Beispiel verwenden wir eine leere Liste
      emit(TasksLoaded(List.from(_tasks)));
    } catch (e) {
      emit(TasksError('Fehler beim Laden der Aufgaben.'));
    }
  }

  void addTask(TaskModel task) {
    _tasks.add(task);
    emit(TasksLoaded(List.from(_tasks)));
  }

  void removeTask(String taskId) {
    _tasks.removeWhere((task) => task.id == taskId);
    emit(TasksLoaded(List.from(_tasks)));
  }

  void updateTask(TaskModel updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      emit(TasksLoaded(List.from(_tasks)));
    }
  }

  /// Methode zur Bestimmung der nächsten Aufgabe
  TaskModel? getNextTask() {
    final now = DateTime.now();
    final pendingTasks = _tasks.where((task) =>
      !task.isDone &&
      (task.endDate == null || task.endDate!.isAfter(now))
    ).toList();

    if (pendingTasks.isEmpty) return null;

    pendingTasks.sort((a, b) {
      // 1. Sortiere nach Enddatum (null wird als sehr weit in der Zukunft betrachtet)
      DateTime aDate = a.endDate ?? DateTime(2100);
      DateTime bDate = b.endDate ?? DateTime(2100);
      int dateComparison = aDate.compareTo(bDate);
      if (dateComparison != 0) return dateComparison;

      // 2. Sortiere nach Priorität (Hoch > Normal > Niedrig)
      int priorityA = _priorityValue(a.priority);
      int priorityB = _priorityValue(b.priority);
      if (priorityA != priorityB) return priorityB.compareTo(priorityA); // Höhere Priorität zuerst

      // 3. Sortiere nach kürzerer Dauer
      return a.duration.compareTo(b.duration);
    });

    return pendingTasks.first;
  }

  /// Hilfsmethode zur Umwandlung der Priorität in einen numerischen Wert
  int _priorityValue(String priority) {
    switch (priority.toLowerCase()) {
      case 'hoch':
        return 3;
      case 'normal':
        return 2;
      case 'niedrig':
        return 1;
      default:
        return 2; // Standardpriorität
    }
  }
}
