import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/history_entry_model.dart';
import '../../logic/history/history_cubit.dart';

/// Zeigt die Historie aller Pomodoro-Einträge.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Historie'),
            centerTitle: true,
          ),
          body: _buildBody(state),
        );
      },
    );
  }

  /// Liefert das passende Widget basierend auf dem aktuellen HistoryState.
  Widget _buildBody(HistoryState state) {
    if (state is HistoryLoading) {
      return _buildLoading();
    } else if (state is HistoryLoaded) {
      return state.history.isEmpty
          ? _buildNoHistory()
          : _buildHistoryList(state.history);
    } else if (state is HistoryError) {
      return _buildError(state.message);
    } else {
      return const SizedBox.shrink();
    }
  }

  /// Zeigt einen Ladeindikator für asynchrone Vorgänge.
  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  /// Zeigt eine Meldung bei leerer Historie.
  Widget _buildNoHistory() {
    return const Center(
      child: Text(
        'Keine Historie vorhanden.',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  /// Zeigt eine Fehlermeldung für aufgetretene Probleme.
  Widget _buildError(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  /// Erstellt eine Liste der historischen Tages-Einträge mit Trennung.
  Widget _buildHistoryList(List<HistoryEntryModel> history) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        return _buildHistoryCard(entry);
      },
      separatorBuilder: (_, __) => const SizedBox(height: 6),
    );
  }

  /// Erstellt ein aufklappbares Element für einen Tag mit Pomodoro-Details.
  Widget _buildHistoryCard(HistoryEntryModel entry) {
    final formattedDate = DateFormat.yMMMMd().format(entry.date);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ExpansionTile(
        title: Text(
          formattedDate,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${entry.pomodoroCount} Pomodoro(s)',
          style: const TextStyle(fontSize: 13),
        ),
        leading: const Icon(Icons.calendar_today_outlined),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        children: entry.pomodoros.map((pomodoro) {
          return ListTile(
            leading: const Icon(Icons.timer),
            title: Text('${pomodoro.duration.inMinutes} Minuten'),
            subtitle: Text('Aufgabe: ${pomodoro.taskTitle}'),
            dense: true,
          );
        }).toList(),
      ),
    );
  }
}
