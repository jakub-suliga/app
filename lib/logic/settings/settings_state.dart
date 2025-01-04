// lib/logic/settings/settings_state.dart

part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  final String eSenseDeviceName;
  // final bool showCompletedTasks; // Entfernen
  final List<String> priorities; // Fixierte Prioritäten
  final Duration pomodoroDuration;
  final Duration shortBreakDuration;
  final Duration longBreakDuration;
  final int sessionsBeforeLongBreak;
  final bool autoStartNextPomodoro;

  const SettingsState({
    required this.eSenseDeviceName,
    // required this.showCompletedTasks, // Entfernen
    required this.priorities,
    required this.pomodoroDuration,
    required this.shortBreakDuration,
    required this.longBreakDuration,
    required this.sessionsBeforeLongBreak,
    required this.autoStartNextPomodoro,
  });

  SettingsState copyWith({
    String? eSenseDeviceName,
    // bool? showCompletedTasks, // Entfernen
    List<String>? priorities,
    Duration? pomodoroDuration,
    Duration? shortBreakDuration,
    Duration? longBreakDuration,
    int? sessionsBeforeLongBreak,
    bool? autoStartNextPomodoro,
  }) {
    return SettingsState(
      eSenseDeviceName: eSenseDeviceName ?? this.eSenseDeviceName,
      // showCompletedTasks: showCompletedTasks ?? this.showCompletedTasks, // Entfernen
      priorities: priorities ?? this.priorities,
      pomodoroDuration: pomodoroDuration ?? this.pomodoroDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
      autoStartNextPomodoro:
          autoStartNextPomodoro ?? this.autoStartNextPomodoro,
    );
  }

  @override
  List<Object> get props => [
        eSenseDeviceName,
        // showCompletedTasks, // Entfernen
        priorities,
        pomodoroDuration,
        shortBreakDuration,
        longBreakDuration,
        sessionsBeforeLongBreak,
        autoStartNextPomodoro,
      ];
}
