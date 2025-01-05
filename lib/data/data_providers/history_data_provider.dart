import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry_model.dart';

/// Ermöglicht das Laden und Speichern der Historie in SharedPreferences.
class HistoryDataProvider {
  static const String _historyKey = 'pomodoro_history';

  /// Lädt alle gespeicherten Historie-Einträge.
  Future<List<HistoryEntryModel>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);
    if (historyJson == null) return [];
    final List<dynamic> decoded = json.decode(historyJson);
    return decoded.map((entry) => HistoryEntryModel.fromJson(entry)).toList();
  }

  /// Speichert die gesamte Liste an Historie-Einträgen.
  Future<void> saveHistory(List<HistoryEntryModel> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = json.encode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_historyKey, historyJson);
  }

  /// Fügt einen einzelnen Eintrag zur Liste der Historie hinzu.
  Future<void> addEntry(HistoryEntryModel entry) async {
    final history = await loadHistory();
    history.add(entry);
    await saveHistory(history);
  }

  /// Fügt eine Pomodoro-Session zu einem bestimmten Datum hinzu.
  Future<void> addPomodoro(DateTime date, PomodoroDetail detail) async {
    final history = await loadHistory();
    final index = history.indexWhere((entry) => _isSameDay(entry.date, date));
    if (index != -1) {
      final existingEntry = history[index];
      final updatedPomodoros = List<PomodoroDetail>.from(existingEntry.pomodoros)..add(detail);
      final updatedEntry = existingEntry.copyWith(pomodoros: updatedPomodoros);
      history[index] = updatedEntry;
    } else {
      history.add(
        HistoryEntryModel(
          date: DateTime(date.year, date.month, date.day),
          pomodoros: [detail],
        ),
      );
    }
    await saveHistory(history);
  }

  /// Vergleicht zwei Datumswerte bezogen auf Tag, Monat und Jahr.
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
