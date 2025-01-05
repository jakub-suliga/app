// lib/presentation/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/history/history_cubit.dart';
import '../../data/models/history_entry_model.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, state) {
        if (state is HistoryLoading) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Historie'),
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is HistoryLoaded) {
          if (state.history.isEmpty) {
            return Scaffold(
              appBar: AppBar(
                title: Text('Historie'),
              ),
              body: Center(child: Text('Keine Historie vorhanden.')),
            );
          }
          return Scaffold(
            appBar: AppBar(
              title: const Text('Historie'),
            ),
            body: ListView.builder(
              itemCount: state.history.length,
              itemBuilder: (context, index) {
                final entry = state.history[index];
                final formattedDate =
                    DateFormat.yMMMMd().format(entry.date);
                return ExpansionTile(
                  title: Text(formattedDate),
                  subtitle: Text('${entry.pomodoroCount} Pomodoro(s)'),
                  children: entry.pomodoros.map((pomodoro) {
                    return ListTile(
                      leading: const Icon(Icons.timer),
                      title: Text(
                          '${pomodoro.duration.inMinutes} Minuten'),
                      subtitle: Text('Aufgabe: ${pomodoro.taskTitle}'),
                    );
                  }).toList(),
                );
              },
            ),
          );
        } else if (state is HistoryError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Historie'),
            ),
            body: Center(child: Text(state.message)),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text('Historie'),
            ),
            body: SizedBox.shrink(),
          );
        }
      },
    );
  }
}
