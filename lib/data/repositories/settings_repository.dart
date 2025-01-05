import '../data_providers/settings_data_provider.dart';

/// Bietet Methoden zum Abrufen und Aktualisieren der Einstellungen aus dem DataProvider.
class SettingsRepository {
  final SettingsDataProvider dataProvider;

  SettingsRepository({required this.dataProvider});

  /// Lädt alle vorhandenen Einstellungen und gibt sie als Map zurück.
  Future<Map<String, dynamic>> getSettings() async {
    return await dataProvider.fetchSettings();
  }

  /// Speichert mehrere Einstellungen gleichzeitig.
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    await dataProvider.saveSettings(settings);
  }

  /// Speichert die neue Pomodoro-Dauer.
  Future<void> updatePomodoroDuration(Duration duration) async {
    await dataProvider.updatePomodoroDuration(duration);
  }

  /// Speichert die neue Dauer für kurze Pausen.
  Future<void> updateShortBreakDuration(Duration duration) async {
    await dataProvider.updateShortBreakDuration(duration);
  }

  /// Speichert die neue Dauer für lange Pausen.
  Future<void> updateLongBreakDuration(Duration duration) async {
    await dataProvider.updateLongBreakDuration(duration);
  }

  /// Legt fest, wie viele Pomodoro-Einheiten vor einer langen Pause absolviert werden.
  Future<void> updateSessionsBeforeLongBreak(int count) async {
    await dataProvider.updateSessionsBeforeLongBreak(count);
  }

  /// Aktiviert oder deaktiviert das automatische Starten der nächsten Pomodoro-Einheit.
  Future<void> updateAutoStartNextPomodoro(bool value) async {
    await dataProvider.updateAutoStartNextPomodoro(value);
  }

  /// Speichert den Namen des eSense-Geräts für die Verbindung.
  Future<void> updateESenseDeviceName(String name) async {
    await dataProvider.updateESenseDeviceName(name);
  }
}
