// lib/logic/history/history_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/history_entry_model.dart';
import '../../data/repositories/history_repository.dart';

part 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  final HistoryRepository historyRepository;

  HistoryCubit({required this.historyRepository})
      : super(HistoryInitial());

  Future<void> loadHistory() async {
    try {
      emit(HistoryLoading());
      final history = await historyRepository.getHistory();
      emit(HistoryLoaded(history));
    } catch (e) {
      emit(HistoryError('Fehler beim Laden der Historie.'));
    }
  }

  Future<void> addPomodoro(DateTime date, PomodoroDetail pomodoroDetail) async {
    if (state is HistoryLoaded) {
      final currentState = state as HistoryLoaded;
      final today = DateTime(date.year, date.month, date.day);
      final existingEntry = currentState.history.firstWhere(
        (entry) =>
            entry.date.year == today.year &&
            entry.date.month == today.month &&
            entry.date.day == today.day,
        orElse: () => HistoryEntryModel(
          date: today,
          pomodoroCount: 0,
          pomodoros: [],
        ),
      );

      List<HistoryEntryModel> updatedHistory = List.from(currentState.history);

      if (existingEntry.pomodoros.isEmpty &&
          !currentState.history.contains(existingEntry)) {
        updatedHistory.add(existingEntry);
      }

      final updatedPomodoros = List<PomodoroDetail>.from(
          existingEntry.pomodoros)
        ..add(pomodoroDetail);
      final updatedEntry = existingEntry.copyWith(
        pomodoroCount: existingEntry.pomodoroCount + 1,
        pomodoros: updatedPomodoros,
      );

      // Entferne alte Einträge und füge aktualisierte hinzu
      updatedHistory.removeWhere(
          (entry) => entry.date.isAtSameMomentAs(existingEntry.date));
      updatedHistory.add(updatedEntry);

      // Sortiere die Historie nach Datum absteigend
      updatedHistory.sort((a, b) => b.date.compareTo(a.date));

      await historyRepository.saveHistory(updatedHistory);
      emit(HistoryLoaded(updatedHistory));
    }
  }
}
