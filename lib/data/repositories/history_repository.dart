import '../data_providers/history_data_provider.dart';
import '../models/history_entry_model.dart';

/// Verwaltet das Laden, Speichern und Aktualisieren der Historie.
class HistoryRepository {
  final HistoryDataProvider dataProvider;

  HistoryRepository({required this.dataProvider});

  /// Lädt die gesamte Historie aus dem DataProvider.
  Future<List<HistoryEntryModel>> getHistory() async {
    return await dataProvider.loadHistory();
  }

  /// Speichert die übergebene Liste von Historie-Einträgen.
  Future<void> saveHistory(List<HistoryEntryModel> history) async {
    await dataProvider.saveHistory(history);
  }

  /// Fügt manuell einen neuen Eintrag in die Historie hinzu.
  Future<void> addEntry(HistoryEntryModel entry) async {
    await dataProvider.addEntry(entry);
  }

  /// Fügt eine neue Pomodoro-Session für das angegebene Datum hinzu.
  Future<void> addPomodoro(DateTime date, PomodoroDetail detail) async {
    await dataProvider.addPomodoro(date, detail);
  }
}
