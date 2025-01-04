// lib/logic/settings/settings_state.dart

part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final String eSenseDeviceName;
  final List<String> priorities; // Fixierte Prioritäten
  final Duration pomodoroDuration;
  final Duration shortBreakDuration;
  final Duration longBreakDuration;
  final int sessionsBeforeLongBreak;
  final bool autoStartNextPomodoro;
  final bool isESenseConnected; // Neues Feld für Verbindungsstatus

  const SettingsState({
    required this.eSenseDeviceName,
    required this.priorities,
    required this.pomodoroDuration,
    required this.shortBreakDuration,
    required this.longBreakDuration,
    required this.sessionsBeforeLongBreak,
    required this.autoStartNextPomodoro,
    required this.isESenseConnected, // Initialisierung
  });

  SettingsState copyWith({
    String? eSenseDeviceName,
    List<String>? priorities,
    Duration? pomodoroDuration,
    Duration? shortBreakDuration,
    Duration? longBreakDuration,
    int? sessionsBeforeLongBreak,
    bool? autoStartNextPomodoro,
    bool? isESenseConnected, // Optionales Feld
  }) {
    return SettingsState(
      eSenseDeviceName: eSenseDeviceName ?? this.eSenseDeviceName,
      priorities: priorities ?? this.priorities,
      pomodoroDuration: pomodoroDuration ?? this.pomodoroDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
      autoStartNextPomodoro:
          autoStartNextPomodoro ?? this.autoStartNextPomodoro,
      isESenseConnected: isESenseConnected ?? this.isESenseConnected,
    );
  }

  @override
  List<Object> get props => [
        eSenseDeviceName,
        priorities,
        pomodoroDuration,
        shortBreakDuration,
        longBreakDuration,
        sessionsBeforeLongBreak,
        autoStartNextPomodoro,
        isESenseConnected,
      ];
}
