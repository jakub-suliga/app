// lib/logic/settings/settings_cubit.dart

import 'package:FocusBuddy/service/eSenseService.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Importiere für StreamSubscription

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final ESenseService _eSenseService;
  late final StreamSubscription<String> _deviceStatusSubscription;

  SettingsCubit(this._eSenseService) : super(const SettingsState(
    eSenseDeviceName: 'eSense-',
    priorities: [
      'Hoch',
      'Mittel',
      'Niedrig',
    ],
    pomodoroDuration: Duration(minutes: 25),
    shortBreakDuration: Duration(minutes: 5),
    longBreakDuration: Duration(minutes: 15),
    sessionsBeforeLongBreak: 4,
    autoStartNextPomodoro: true,
    isESenseConnected: false,
  )) {
    _loadSettings();
    // Listen to the deviceStatusStream to update isESenseConnected
    _deviceStatusSubscription = _eSenseService.deviceStatusStream.listen((status) {
      bool isConnected = status == 'Connected';
      emit(state.copyWith(isESenseConnected: isConnected));
    });
  }

  @override
  Future<void> close() {
    _deviceStatusSubscription.cancel();
    _eSenseService.dispose(); // Stelle sicher, dass die Service-Instanz korrekt freigegeben wird
    return super.close();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final eSenseDeviceName = prefs.getString('eSenseDeviceName') ?? 'DefaultDevice';
    final pomodoroMinutes = prefs.getInt('pomodoroDuration') ?? 25;
    final shortBreakMinutes = prefs.getInt('shortBreakDuration') ?? 5;
    final longBreakMinutes = prefs.getInt('longBreakDuration') ?? 15;
    final sessionsBeforeLongBreak = prefs.getInt('sessionsBeforeLongBreak') ?? 4;
    final autoStartNextPomodoro = prefs.getBool('autoStartNextPomodoro') ?? true;

    emit(state.copyWith(
      eSenseDeviceName: eSenseDeviceName,
      pomodoroDuration: Duration(minutes: pomodoroMinutes),
      shortBreakDuration: Duration(minutes: shortBreakMinutes),
      longBreakDuration: Duration(minutes: longBreakMinutes),
      sessionsBeforeLongBreak: sessionsBeforeLongBreak,
      autoStartNextPomodoro: autoStartNextPomodoro,
    ));
  }

  // Methode zur Aktualisierung der Pomodoro-Dauer
  void setPomodoroDuration(Duration newDuration) async {
    final clampedDuration = newDuration.inMinutes > 99
        ? Duration(minutes: 99)
        : newDuration;

    emit(state.copyWith(pomodoroDuration: clampedDuration));
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('pomodoroDuration', clampedDuration.inMinutes);
  }

  // Methode zur Aktualisierung der kurzen Pause
  void setShortBreakDuration(Duration newDuration) async {
    emit(state.copyWith(shortBreakDuration: newDuration));
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('shortBreakDuration', newDuration.inMinutes);
  }

  // Methode zur Aktualisierung der langen Pause
  void setLongBreakDuration(Duration newDuration) async {
    emit(state.copyWith(longBreakDuration: newDuration));
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('longBreakDuration', newDuration.inMinutes);
  }

  // Methode zur Aktualisierung der Sitzungen vor langer Pause
  void setSessionsBeforeLongBreak(int count) async {
    emit(state.copyWith(sessionsBeforeLongBreak: count));
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('sessionsBeforeLongBreak', count);
  }

  // Methode zum Umschalten des automatischen Startens der nächsten Pomodoro-Einheit
  void toggleAutoStartNextPomodoro(bool value) async {
    emit(state.copyWith(autoStartNextPomodoro: value));
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('autoStartNextPomodoro', value);
  }

  // Methode zur Aktualisierung des eSense-Gerätenamens
  void setESenseDeviceName(String name) async {
    emit(state.copyWith(eSenseDeviceName: name));
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('eSenseDeviceName', name);
  }

  // Methode zum Verbinden mit eSense
  Future<void> connectESense() async {
    try {
      await _eSenseService.initialize(state.eSenseDeviceName);
      // Der Verbindungsstatus wird automatisch über den Stream aktualisiert
    } catch (e) {
      // Handle connection errors
      debugPrint('Fehler beim Verbinden mit eSense: $e');
      // Optional: Zeige eine SnackBar oder ein Dialogfenster an
    }
  }

  // Methode zum Trennen von eSense
  Future<void> disconnectESense() async {
    try {
      await _eSenseService.disconnect();
      // Der Verbindungsstatus wird automatisch über den Stream aktualisiert
    } catch (e) {
      // Handle disconnection errors
      debugPrint('Fehler beim Trennen von eSense: $e');
      // Optional: Zeige eine SnackBar oder ein Dialogfenster an
    }
  }
}
