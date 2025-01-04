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
