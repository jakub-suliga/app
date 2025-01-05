// lib/logic/settings/settings_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/settings_repository.dart';
import '../../service/eSenseService.dart'; // Stelle sicher, dass dieser Pfad korrekt ist
import 'dart:async'; // Für StreamSubscription

part 'settings_state.dart';

/// Verwaltet und speichert die Einstellungen wie Pomodoro-Dauer und eSense-Verbindungsstatus.
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
    _deviceStatusSubscription = _eSenseService.deviceStatusStream.listen((status) {
      bool isConnected = status == 'Connected';
      emit(state.copyWith(isESenseConnected: isConnected));
    });
  }

  @override
  Future<void> close() {
    _deviceStatusSubscription.cancel();
    _eSenseService.dispose();
    return super.close();
  }

  /// Lädt die gespeicherten Einstellungen aus dem Repository.
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

  /// Speichert die neue Pomodoro-Dauer.
  Future<void> setPomodoroDuration(Duration newDuration) async {
    try {
      await settingsRepository.updatePomodoroDuration(newDuration);
      emit(state.copyWith(pomodoroDuration: newDuration));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: e.toString()));
    }
  }

  /// Speichert die neue Dauer für kurze Pausen.
  Future<void> setShortBreakDuration(Duration newDuration) async {
    try {
      await settingsRepository.updateShortBreakDuration(newDuration);
      emit(state.copyWith(shortBreakDuration: newDuration));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: e.toString()));
    }
  }

  /// Speichert die neue Dauer für lange Pausen.
  Future<void> setLongBreakDuration(Duration newDuration) async {
    try {
      await settingsRepository.updateLongBreakDuration(newDuration);
      emit(state.copyWith(longBreakDuration: newDuration));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: e.toString()));
    }
  }

  /// Legt fest, nach wie vielen Pomodoro-Einheiten eine lange Pause eingelegt wird.
  Future<void> setSessionsBeforeLongBreak(int count) async {
    try {
      await settingsRepository.updateSessionsBeforeLongBreak(count);
      emit(state.copyWith(sessionsBeforeLongBreak: count));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: e.toString()));
    }
  }

  /// Aktiviert oder deaktiviert das automatische Starten der nächsten Pomodoro-Einheit.
  Future<void> toggleAutoStartNextPomodoro(bool value) async {
    try {
      await settingsRepository.updateAutoStartNextPomodoro(value);
      emit(state.copyWith(autoStartNextPomodoro: value));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: e.toString()));
    }
  }

  /// Speichert den Namen des eSense-Geräts, das verbunden werden soll.
  Future<void> setESenseDeviceName(String name) async {
    try {
      await settingsRepository.updateESenseDeviceName(name);
      emit(state.copyWith(eSenseDeviceName: name));
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: e.toString()));
    }
  }

  /// Verbindet sich mit dem eSense-Gerät mithilfe des gespeicherten Namens.
  Future<void> connectESense() async {
    try {
      await _eSenseService.initialize(state.eSenseDeviceName);
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: 'Fehler beim Verbinden mit eSense: $e'));
    }
  }

  /// Trennt die Verbindung zum eSense-Gerät.
  Future<void> disconnectESense() async {
    try {
      await _eSenseService.disconnect();
    } catch (e) {
      emit(state.copyWith(status: SettingsStatus.error, errorMessage: 'Fehler beim Trennen von eSense: $e'));
    }
  }
}
