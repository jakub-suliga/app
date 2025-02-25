part of 'settings_cubit.dart';

/// Definiert mögliche Zustände für Einstellungen wie Pomodoro-Dauer und eSense-Verbindung.
enum SettingsStatus { initial, loading, loaded, error }

/// Enthält alle relevanten Einstellungen und den aktuellen Verbindungsstatus zum eSense-Gerät.
class SettingsState extends Equatable {
  final String eSenseDeviceName;
  final Duration pomodoroDuration;
  final Duration shortBreakDuration;
  final Duration longBreakDuration;
  final int sessionsBeforeLongBreak;
  final bool autoStartNextPomodoro;
  final bool isESenseConnected;
  final SettingsStatus status;
  final String? errorMessage;

  const SettingsState({
    required this.eSenseDeviceName,
    required this.pomodoroDuration,
    required this.shortBreakDuration,
    required this.longBreakDuration,
    required this.sessionsBeforeLongBreak,
    required this.autoStartNextPomodoro,
    required this.isESenseConnected,
    required this.status,
    this.errorMessage,
  });

  /// Standardwerte für den allerersten Zustand.
  factory SettingsState.initial() {
    return const SettingsState(
      eSenseDeviceName: 'eSense-',
      pomodoroDuration: Duration(minutes: 25),
      shortBreakDuration: Duration(minutes: 5),
      longBreakDuration: Duration(minutes: 15),
      sessionsBeforeLongBreak: 4,
      autoStartNextPomodoro: true,
      isESenseConnected: false,
      status: SettingsStatus.initial,
      errorMessage: null,
    );
  }

  /// Erstellt einen neuen Zustand auf Basis des aktuellen, überschreibt dabei nur die angegebenen Felder.
  SettingsState copyWith({
    String? eSenseDeviceName,
    Duration? pomodoroDuration,
    Duration? shortBreakDuration,
    Duration? longBreakDuration,
    int? sessionsBeforeLongBreak,
    bool? autoStartNextPomodoro,
    bool? isESenseConnected,
    SettingsStatus? status,
    String? errorMessage,
  }) {
    return SettingsState(
      eSenseDeviceName: eSenseDeviceName ?? this.eSenseDeviceName,
      pomodoroDuration: pomodoroDuration ?? this.pomodoroDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      sessionsBeforeLongBreak: sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
      autoStartNextPomodoro: autoStartNextPomodoro ?? this.autoStartNextPomodoro,
      isESenseConnected: isESenseConnected ?? this.isESenseConnected,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        eSenseDeviceName,
        pomodoroDuration,
        shortBreakDuration,
        longBreakDuration,
        sessionsBeforeLongBreak,
        autoStartNextPomodoro,
        isESenseConnected,
        status,
        errorMessage,
      ];
}
