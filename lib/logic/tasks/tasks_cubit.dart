import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/tasks_repository.dart';
import '../../data/models/task_model.dart';

class TasksCubit extends Cubit<TasksState> {
  final TasksRepository tasksRepo;

  TasksCubit({required this.tasksRepo}) : super(TasksInitial());

  Future<void> loadTasks() async {
    emit(TasksLoading());
    try {
      final tasks = await tasksRepo.getAllTasks();
      emit(TasksLoaded(tasks));
    } catch (e) {
      emit(TasksError('Fehler beim Laden: $e'));
    }
  }

  Future<void> addTask(TaskModel task) async {
    await tasksRepo.addTask(task);
    await loadTasks();
  }

  Future<void> deleteTask(TaskModel task) async {
    await tasksRepo.removeTask(task);
    await loadTasks();
  }

  Future<void> updateTask(TaskModel task) async {
    await tasksRepo.updateTask(task);
    await loadTasks();
  }
}


abstract class TasksState {}

class TasksInitial extends TasksState {}

class TasksLoading extends TasksState {}

class TasksLoaded extends TasksState {
  final List<TaskModel> tasks;
  TasksLoaded(this.tasks);
}

class TasksError extends TasksState {
  final String message;
  TasksError(this.message);
}