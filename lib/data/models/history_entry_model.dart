// lib/data/models/history_entry_model.dart


class HistoryEntryModel {
  final DateTime date;
  final List<PomodoroDetail> pomodoros;

  HistoryEntryModel({
    required this.date,
    this.pomodoros = const [],
  });

  int get pomodoroCount => pomodoros.length;

  HistoryEntryModel copyWith({
    DateTime? date,
    List<PomodoroDetail>? pomodoros,
  }) {
    return HistoryEntryModel(
      date: date ?? this.date,
      pomodoros: pomodoros ?? this.pomodoros,
    );
  }

  factory HistoryEntryModel.fromJson(Map<String, dynamic> json) {
    return HistoryEntryModel(
      date: DateTime.parse(json['date']),
      pomodoros: (json['pomodoros'] as List<dynamic>?)
              ?.map((e) => PomodoroDetail.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'pomodoros': pomodoros.map((e) => e.toJson()).toList(),
    };
  }
}

class PomodoroDetail {
  final Duration duration;
  final String taskTitle;

  PomodoroDetail({
    required this.duration,
    required this.taskTitle,
  });

  factory PomodoroDetail.fromJson(Map<String, dynamic> json) {
    return PomodoroDetail(
      duration: Duration(seconds: json['duration']),
      taskTitle: json['taskTitle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duration': duration.inSeconds,
      'taskTitle': taskTitle,
    };
  }
}
