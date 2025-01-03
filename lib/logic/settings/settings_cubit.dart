// lib/logic/settings/settings_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final String eSenseDeviceName;
  final bool showCompletedTasks;
  final List<String> priorities;

  // Neue Pomodoro-Einstellungen
  final Duration pomodoroDuration;
  final Duration shortBreakDuration;
  final Duration longBreakDuration;
  final int sessionsBeforeLongBreak;
  final bool autoStartNextPomodoro;

  const SettingsState({
    required this.eSenseDeviceName,
    required this.showCompletedTasks,
    required this.priorities,
    this.pomodoroDuration = const Duration(minutes: 25),
    this.shortBreakDuration = const Duration(minutes: 5),
    this.longBreakDuration = const Duration(minutes: 15),
    this.sessionsBeforeLongBreak = 4,
    this.autoStartNextPomodoro = false,
  });

  SettingsState copyWith({
    String? eSenseDeviceName,
    bool? showCompletedTasks,
    List<String>? priorities,
    Duration? pomodoroDuration,
    Duration? shortBreakDuration,
    Duration? longBreakDuration,
    int? sessionsBeforeLongBreak,
    bool? autoStartNextPomodoro,
  }) {
    return SettingsState(
      eSenseDeviceName: eSenseDeviceName ?? this.eSenseDeviceName,
      showCompletedTasks: showCompletedTasks ?? this.showCompletedTasks,
      priorities: priorities ?? this.priorities,
      pomodoroDuration: pomodoroDuration ?? this.pomodoroDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      sessionsBeforeLongBreak: sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
      autoStartNextPomodoro: autoStartNextPomodoro ?? this.autoStartNextPomodoro,
    );
  }

  @override
  List<Object> get props => [
        eSenseDeviceName,
        showCompletedTasks,
        priorities,
        pomodoroDuration,
        shortBreakDuration,
        longBreakDuration,
        sessionsBeforeLongBreak,
        autoStartNextPomodoro,
      ];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit()
      : super(const SettingsState(
          eSenseDeviceName: 'DefaultDeviceName',
          showCompletedTasks: true,
          priorities: ['Hoch', 'Normal', 'Niedrig'], // Standardprioritäten
        ));

  void setESenseDeviceName(String newName) {
    emit(state.copyWith(eSenseDeviceName: newName));
  }

  void toggleShowCompletedTasks(bool value) {
    emit(state.copyWith(showCompletedTasks: value));
  }

  void addPriority(String priority) {
    if (!state.priorities.contains(priority)) {
      final updatedPriorities = List<String>.from(state.priorities)..add(priority);
      emit(state.copyWith(priorities: updatedPriorities));
    }
  }

  void removePriority(String priority) {
    if (state.priorities.contains(priority)) {
      final updatedPriorities = List<String>.from(state.priorities)..remove(priority);
      emit(state.copyWith(priorities: updatedPriorities));
    }
  }

  void editPriority(String oldPriority, String newPriority) {
    final updatedPriorities = state.priorities.map((prio) => prio == oldPriority ? newPriority : prio).toList();
    emit(state.copyWith(priorities: updatedPriorities));
  }

  void reorderPriorities(int oldIndex, int newIndex) {
    final updatedPriorities = List<String>.from(state.priorities);
    final item = updatedPriorities.removeAt(oldIndex);
    updatedPriorities.insert(newIndex, item);
    emit(state.copyWith(priorities: updatedPriorities));
  }

  // Neue Methoden zur Verwaltung der Pomodoro-Einstellungen

  void setPomodoroDuration(Duration duration) {
    emit(state.copyWith(pomodoroDuration: duration));
  }

  void setShortBreakDuration(Duration duration) {
    emit(state.copyWith(shortBreakDuration: duration));
  }

  void setLongBreakDuration(Duration duration) {
    emit(state.copyWith(longBreakDuration: duration));
  }

  void setSessionsBeforeLongBreak(int sessions) {
    emit(state.copyWith(sessionsBeforeLongBreak: sessions));
  }

  void toggleAutoStartNextPomodoro(bool value) {
    emit(state.copyWith(autoStartNextPomodoro: value));
  }
}
