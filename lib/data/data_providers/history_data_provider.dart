// lib/data/data_providers/history_data_provider.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry_model.dart';

class HistoryDataProvider {
  static const String _historyKey = 'pomodoro_history';

  Future<List<HistoryEntryModel>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);
    if (historyJson == null) return [];
    final List<dynamic> decoded = json.decode(historyJson);
    return decoded
        .map((entry) => HistoryEntryModel.fromJson(entry))
        .toList();
  }

  Future<void> saveHistory(List<HistoryEntryModel> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson =
        json.encode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_historyKey, historyJson);
  }

  Future<void> addEntry(HistoryEntryModel entry) async {
    final history = await loadHistory();
    history.add(entry);
    await saveHistory(history);
  }
}
