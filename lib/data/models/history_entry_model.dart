/// Enthält das Datum und eine Liste von Pomodoro-Einheiten für diesen Tag.
class HistoryEntryModel {
  final DateTime date;
  final List<PomodoroDetail> pomodoros;

  /// Erstellt einen Eintrag mit Datum und optionalen Pomodoros.
  HistoryEntryModel({
    required this.date,
    this.pomodoros = const [],
  });

  /// Gibt die Anzahl aller Pomodoro-Einheiten in dieser History zurück.
  int get pomodoroCount => pomodoros.length;

  /// Erzeugt eine Kopie dieses Eintrags mit optional geänderten Feldern.
  HistoryEntryModel copyWith({
    DateTime? date,
    List<PomodoroDetail>? pomodoros,
  }) {
    return HistoryEntryModel(
      date: date ?? this.date,
      pomodoros: pomodoros ?? this.pomodoros,
    );
  }

  /// Erstellt ein HistoryEntryModel aus einer JSON-Struktur.
  factory HistoryEntryModel.fromJson(Map<String, dynamic> json) {
    return HistoryEntryModel(
      date: DateTime.parse(json['date']),
      pomodoros: (json['pomodoros'] as List<dynamic>?)
              ?.map((e) => PomodoroDetail.fromJson(e))
              .toList() ??
          [],
    );
  }

  /// Wandelt diesen Eintrag in eine JSON-Struktur um.
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'pomodoros': pomodoros.map((e) => e.toJson()).toList(),
    };
  }
}

/// Beschreibt einzelne Details einer absolvierten Pomodoro-Einheit.
class PomodoroDetail {
  final Duration duration;
  final String taskTitle;

  /// Erstellt eine Pomodoro-Einheit mit Dauer und passendem Aufgabentitel.
  PomodoroDetail({
    required this.duration,
    required this.taskTitle,
  });

  /// Erstellt ein PomodoroDetail aus einer JSON-Struktur.
  factory PomodoroDetail.fromJson(Map<String, dynamic> json) {
    return PomodoroDetail(
      duration: Duration(seconds: json['duration']),
      taskTitle: json['taskTitle'],
    );
  }

  /// Wandelt diese Pomodoro-Einheit in eine JSON-Struktur um.
  Map<String, dynamic> toJson() {
    return {
      'duration': duration.inSeconds,
      'taskTitle': taskTitle,
    };
  }
}
