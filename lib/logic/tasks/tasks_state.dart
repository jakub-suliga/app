part of 'tasks_cubit.dart';

/// Stellt unterschiedliche Zustände im Aufgaben-Cubit bereit.
abstract class TasksState extends Equatable {
  const TasksState();

  @override
  List<Object?> get props => [];
}

/// Ausgangszustand beim Laden oder noch nicht initialisiert.
class TasksInitial extends TasksState {}

/// Signalisiert, dass Aufgaben geladen werden.
class TasksLoading extends TasksState {}

/// Enthält die Listen aktiver und erledigter Aufgaben.
class TasksLoaded extends TasksState {
  final List<TaskModel> activeTasks;
  final List<TaskModel> completedTasks;

  const TasksLoaded({
    required this.activeTasks,
    required this.completedTasks,
  });

  @override
  List<Object?> get props => [activeTasks, completedTasks];
}

/// Beschreibt einen Fehlerzustand mit passender Meldung.
class TasksError extends TasksState {
  final String message;

  const TasksError(this.message);

  @override
  List<Object?> get props => [message];
}
