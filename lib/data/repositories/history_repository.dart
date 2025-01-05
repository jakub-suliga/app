// lib/data/repositories/history_repository.dart

import '../data_providers/history_data_provider.dart';
import '../models/history_entry_model.dart';

class HistoryRepository {
  final HistoryDataProvider dataProvider;

  HistoryRepository({required this.dataProvider});

  Future<List<HistoryEntryModel>> getHistory() => dataProvider.loadHistory();

  Future<void> addHistoryEntry(HistoryEntryModel entry) =>
      dataProvider.addEntry(entry);

  Future<void> saveHistory(List<HistoryEntryModel> history) =>
      dataProvider.saveHistory(history);
}
