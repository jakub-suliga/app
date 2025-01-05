// lib/data/repositories/history_repository.dart

import '../data_providers/history_data_provider.dart';
import '../models/history_entry_model.dart';

class HistoryRepository {
  final HistoryDataProvider dataProvider;

  HistoryRepository({required this.dataProvider});

  Future<List<HistoryEntryModel>> getHistory() async {
    return await dataProvider.loadHistory();
  }

  Future<void> saveHistory(List<HistoryEntryModel> history) async {
    await dataProvider.saveHistory(history);
  }

  /// Methode zum Hinzufügen eines Eintrags
  Future<void> addEntry(HistoryEntryModel entry) async {
    await dataProvider.addEntry(entry);
  }

  /// Methode zum Hinzufügen einer Pomodoro-Session
  Future<void> addPomodoro(DateTime date, PomodoroDetail detail) async {
    await dataProvider.addPomodoro(date, detail);
  }
}
