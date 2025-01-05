// lib/data/repositories/settings_repository.dart

import '../data_providers/settings_data_provider.dart';

class SettingsRepository {
  final SettingsDataProvider dataProvider;

  SettingsRepository({required this.dataProvider});

  Future<Map<String, dynamic>> getSettings() async {
    return await dataProvider.fetchSettings();
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    await dataProvider.saveSettings(settings);
  }

  // Spezifische Methoden für einzelne Einstellungen
  Future<void> updatePomodoroDuration(Duration duration) async {
    await dataProvider.updatePomodoroDuration(duration);
  }

  Future<void> updateShortBreakDuration(Duration duration) async {
    await dataProvider.updateShortBreakDuration(duration);
  }

  Future<void> updateLongBreakDuration(Duration duration) async {
    await dataProvider.updateLongBreakDuration(duration);
  }

  Future<void> updateSessionsBeforeLongBreak(int count) async {
    await dataProvider.updateSessionsBeforeLongBreak(count);
  }

  Future<void> updateAutoStartNextPomodoro(bool value) async {
    await dataProvider.updateAutoStartNextPomodoro(value);
  }

  Future<void> updateESenseDeviceName(String name) async {
    await dataProvider.updateESenseDeviceName(name);
  }
}
