// lib/logic/settings/settings_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/constants.dart'; // Importieren Sie die Konstante

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit()
      : super(SettingsState(
          eSenseDeviceName: '',
          priorities: AppConstants.fixedPriorities,
          pomodoroDuration: Duration(minutes: 25),
          shortBreakDuration: Duration(minutes: 5),
          longBreakDuration: Duration(minutes: 15),
          sessionsBeforeLongBreak: 4,
          autoStartNextPomodoro: false,
        ));

  void setESenseDeviceName(String name) {
    emit(state.copyWith(eSenseDeviceName: name));
  }

  // Entfernen der Methode zur Anzeige erledigter Aufgaben
  // void toggleShowCompletedTasks(bool value) {
  //   emit(state.copyWith(showCompletedTasks: value));
  // }

  // Entfernen Sie alle Methoden zum Hinzufügen, Bearbeiten und Löschen von Prioritäten

  // Methoden zum Aktualisieren der Pomodoro-Einstellungen bleiben erhalten
  void setPomodoroDuration(Duration duration) {
    emit(state.copyWith(pomodoroDuration: duration));
  }

  void setShortBreakDuration(Duration duration) {
    emit(state.copyWith(shortBreakDuration: duration));
  }

  void setLongBreakDuration(Duration duration) {
    emit(state.copyWith(longBreakDuration: duration));
  }

  void setSessionsBeforeLongBreak(int count) {
    emit(state.copyWith(sessionsBeforeLongBreak: count));
  }

  void toggleAutoStartNextPomodoro(bool value) {
    emit(state.copyWith(autoStartNextPomodoro: value));
  }

  // Keine Methoden mehr zum Bearbeiten von Prioritäten
}
