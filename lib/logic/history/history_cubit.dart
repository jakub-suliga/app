// lib/logic/history/history_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/history_entry_model.dart';
import '../../data/repositories/history_repository.dart';

part 'history_state.dart';

/// Verarbeitet das Laden und Hinzufügen von Pomodoro-Einträgen in der Historie.
class HistoryCubit extends Cubit<HistoryState> {
  final HistoryRepository historyRepository;

  HistoryCubit({required this.historyRepository}) : super(HistoryInitial()) {
    loadHistory();
  }

  /// Lädt alle Einträge der Historie aus dem Repository.
  Future<void> loadHistory() async {
    try {
      emit(HistoryLoading());
      final history = await historyRepository.getHistory();
      emit(HistoryLoaded(history));
    } catch (e) {
      emit(HistoryError('Fehler beim Laden der Historie.'));
    }
  }

  /// Fügt einen neuen Pomodoro-Eintrag für ein bestimmtes Datum hinzu.
  Future<void> addPomodoro(DateTime date, PomodoroDetail pomodoroDetail) async {
    try {
      await historyRepository.addPomodoro(date, pomodoroDetail);
      loadHistory();
    } catch (e) {
      emit(HistoryError('Fehler beim Hinzufügen der Pomodoro-Session.'));
    }
  }
}

