// lib/logic/history/history_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/history_entry_model.dart';
import '../../data/repositories/history_repository.dart';

part 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  final HistoryRepository historyRepository;

  HistoryCubit({required this.historyRepository})
      : super(HistoryInitial()) {
    loadHistory();
  }

  /// Lädt die Historie
  Future<void> loadHistory() async {
    try {
      emit(HistoryLoading());
      final history = await historyRepository.getHistory();
      emit(HistoryLoaded(history));
    } catch (e) {
      emit(HistoryError('Fehler beim Laden der Historie.'));
    }
  }

  /// Fügt eine neue Pomodoro-Session hinzu
  Future<void> addPomodoro(DateTime date, PomodoroDetail pomodoroDetail) async {
    try {
      await historyRepository.addPomodoro(date, pomodoroDetail);
      loadHistory();
    } catch (e) {
      emit(HistoryError('Fehler beim Hinzufügen der Pomodoro-Session.'));
    }
  }
}
