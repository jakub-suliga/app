// lib/logic/tasks/tasks_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/task_model.dart';

// Definieren Sie den State für Tasks
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

  // Weitere Methoden nach Bedarf
}
