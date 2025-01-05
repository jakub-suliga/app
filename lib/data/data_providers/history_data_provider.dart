// lib/data/data_providers/history_data_provider.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry_model.dart';

class HistoryDataProvider {
  static const String _historyKey = 'pomodoro_history';

  /// Lädt die Historie aus SharedPreferences
  Future<List<HistoryEntryModel>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);
    if (historyJson == null) return [];
    final List<dynamic> decoded = json.decode(historyJson);
    return decoded
        .map((entry) => HistoryEntryModel.fromJson(entry))
        .toList();
  }

  /// Speichert die gesamte Historie in SharedPreferences
  Future<void> saveHistory(List<HistoryEntryModel> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson =
        json.encode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_historyKey, historyJson);
  }

  /// Fügt einen neuen Eintrag zur Historie hinzu
  Future<void> addEntry(HistoryEntryModel entry) async {
    final history = await loadHistory();
    history.add(entry);
    await saveHistory(history);
  }

  /// Methode zum Hinzufügen einer Pomodoro-Session
  Future<void> addPomodoro(DateTime date, PomodoroDetail detail) async {
    final history = await loadHistory();
    // Überprüfen, ob ein Eintrag für das Datum existiert
    final index = history.indexWhere((entry) => _isSameDay(entry.date, date));
    if (index != -1) {
      final existingEntry = history[index];
      final updatedPomodoros = List<PomodoroDetail>.from(existingEntry.pomodoros)
        ..add(detail);
      final updatedEntry = existingEntry.copyWith(
        pomodoros: updatedPomodoros,
      );
      history[index] = updatedEntry;
    } else {
      history.add(HistoryEntryModel(
        date: DateTime(date.year, date.month, date.day),
        pomodoros: [detail],
      ));
    }
    await saveHistory(history);
  }

  /// Hilfsmethode zum Vergleichen von zwei Daten (ohne Zeit)
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
