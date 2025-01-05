// lib/data/models/history_entry_model.dart

import 'package:equatable/equatable.dart';

class HistoryEntryModel extends Equatable {
  final DateTime date;
  final int pomodoroCount;
  final List<PomodoroDetail> pomodoros;

  const HistoryEntryModel({
    required this.date,
    required this.pomodoroCount,
    required this.pomodoros,
  });

  factory HistoryEntryModel.fromJson(Map<String, dynamic> json) {
    return HistoryEntryModel(
      date: DateTime.parse(json['date']),
      pomodoroCount: json['pomodoroCount'],
      pomodoros: (json['pomodoros'] as List)
          .map((e) => PomodoroDetail.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'pomodoroCount': pomodoroCount,
        'pomodoros': pomodoros.map((e) => e.toJson()).toList(),
      };

  // Hinzufügen der copyWith-Methode
  HistoryEntryModel copyWith({
    DateTime? date,
    int? pomodoroCount,
    List<PomodoroDetail>? pomodoros,
  }) {
    return HistoryEntryModel(
      date: date ?? this.date,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
      pomodoros: pomodoros ?? this.pomodoros,
    );
  }

  @override
  List<Object?> get props => [date, pomodoroCount, pomodoros];
}

class PomodoroDetail extends Equatable {
  final Duration duration;
  final String taskTitle;

  const PomodoroDetail({
    required this.duration,
    required this.taskTitle,
  });

  factory PomodoroDetail.fromJson(Map<String, dynamic> json) {
    return PomodoroDetail(
      duration: Duration(minutes: json['durationMinutes']),
      taskTitle: json['taskTitle'],
    );
  }

  Map<String, dynamic> toJson() => {
        'durationMinutes': duration.inMinutes,
        'taskTitle': taskTitle,
      };

  @override
  List<Object?> get props => [duration, taskTitle];
}
