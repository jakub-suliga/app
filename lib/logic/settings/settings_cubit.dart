// lib/logic/settings/settings_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/settings_repository.dart';
import '../../service/eSenseService.dart'; // Stelle sicher, dass dieser Pfad korrekt ist
import 'dart:async'; // Für StreamSubscription

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository settingsRepository;
  final ESenseService _eSenseService;
  late final StreamSubscription<String> _deviceStatusSubscription;

  SettingsCubit({
    required this.settingsRepository,
    required ESenseService eSenseService,
  })  : _eSenseService = eSenseService,
        super(SettingsState.initial()) {
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
    emit(state.copyWith(status: SettingsStatus.loading));
    try {
      final settings = await settingsRepository.getSettings();
      emit(state.copyWith(
        eSenseDeviceName: settings['eSenseDeviceName'],
        pomodoroDuration: settings['pomodoroDuration'],
        shortBreakDuration: settings['shortBreakDuration'],
        longBreakDuration: settings['longBreakDuration'],
        sessionsBeforeLongBreak: settings['sessionsBeforeLongBreak'],
        autoStartNextPomodoro: settings['autoStartNextPomodoro'],
        status: SettingsStatus.loaded,
      ));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: e.toString()));
    }
  }

  // Methoden zur Aktualisierung der Einstellungen

  Future<void> setPomodoroDuration(Duration newDuration) async {
    try {
      await settingsRepository.updatePomodoroDuration(newDuration);
      emit(state.copyWith(pomodoroDuration: newDuration));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> setShortBreakDuration(Duration newDuration) async {
    try {
      await settingsRepository.updateShortBreakDuration(newDuration);
      emit(state.copyWith(shortBreakDuration: newDuration));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> setLongBreakDuration(Duration newDuration) async {
    try {
      await settingsRepository.updateLongBreakDuration(newDuration);
      emit(state.copyWith(longBreakDuration: newDuration));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> setSessionsBeforeLongBreak(int count) async {
    try {
      await settingsRepository.updateSessionsBeforeLongBreak(count);
      emit(state.copyWith(sessionsBeforeLongBreak: count));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> toggleAutoStartNextPomodoro(bool value) async {
    try {
      await settingsRepository.updateAutoStartNextPomodoro(value);
      emit(state.copyWith(autoStartNextPomodoro: value));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> setESenseDeviceName(String name) async {
    try {
      await settingsRepository.updateESenseDeviceName(name);
      emit(state.copyWith(eSenseDeviceName: name));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: e.toString()));
    }
  }

  // Methoden zur Verbindung mit eSense

  Future<void> connectESense() async {
    try {
      await _eSenseService.initialize(state.eSenseDeviceName);
      // Der Verbindungsstatus wird automatisch über den Stream aktualisiert
    } catch (e) {
      // Handle connection errors
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: 'Fehler beim Verbinden mit eSense: $e'));
    }
  }

  Future<void> disconnectESense() async {
    try {
      await _eSenseService.disconnect();
      // Der Verbindungsstatus wird automatisch über den Stream aktualisiert
    } catch (e) {
      // Handle disconnection errors
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: 'Fehler beim Trennen von eSense: $e'));
    }
  }
}
