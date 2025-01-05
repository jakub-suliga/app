part of 'history_cubit.dart';

/// Definiert die möglichen Zustände der Historie, z. B. beim Laden oder bei Fehlern.
abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object> get props => [];
}

/// Anfangszustand, bevor die Historie geladen wurde.
class HistoryInitial extends HistoryState {}

/// Zeigt an, dass die Historie gerade geladen wird.
class HistoryLoading extends HistoryState {}

/// Enthält die geladenen Historie-Einträge.
class HistoryLoaded extends HistoryState {
  final List<HistoryEntryModel> history;

  const HistoryLoaded(this.history);

  @override
  List<Object> get props => [history];
}

/// Beschreibt einen Fehlerzustand mit passender Meldung.
class HistoryError extends HistoryState {
  final String message;

  const HistoryError(this.message);

  @override
  List<Object> get props => [message];
}
