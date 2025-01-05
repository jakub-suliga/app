// lib/logic/tasks/tasks_state.dart

part of 'tasks_cubit.dart';

abstract class TasksState extends Equatable {
  const TasksState();

  @override
  List<Object> get props => [];
}

class TasksInitial extends TasksState {}

class TasksLoading extends TasksState {}

class TasksLoaded extends TasksState {
  final List<TaskModel> activeTasks;
  final List<TaskModel> completedTasks;

  const TasksLoaded({
    required this.activeTasks,
    required this.completedTasks,
  });

  @override
  List<Object> get props => [activeTasks, completedTasks];
}

class TasksError extends TasksState {
  final String message;

  const TasksError(this.message);

  @override
  List<Object> get props => [message];
}
