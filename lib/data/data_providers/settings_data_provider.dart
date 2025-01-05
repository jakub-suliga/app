import 'package:shared_preferences/shared_preferences.dart';

/// Verwaltet das Speichern und Abrufen verschiedener Einstellungen in SharedPreferences.
class SettingsDataProvider {
  static const String _pomodoroDurationKey = 'pomodoroDuration';
  static const String _shortBreakDurationKey = 'shortBreakDuration';
  static const String _longBreakDurationKey = 'longBreakDuration';
  static const String _sessionsBeforeLongBreakKey = 'sessionsBeforeLongBreak';
  static const String _autoStartNextPomodoroKey = 'autoStartNextPomodoro';
  static const String _eSenseDeviceNameKey = 'eSenseDeviceName';

  /// Lädt sämtliche Einstellungen und gibt sie als Map zurück.
  Future<Map<String, dynamic>> fetchSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'pomodoroDuration': prefs.getInt(_pomodoroDurationKey) ?? 25 * 60,
      'shortBreakDuration': prefs.getInt(_shortBreakDurationKey) ?? 5 * 60,
      'longBreakDuration': prefs.getInt(_longBreakDurationKey) ?? 15 * 60,
      'sessionsBeforeLongBreak': prefs.getInt(_sessionsBeforeLongBreakKey) ?? 4,
      'autoStartNextPomodoro': prefs.getBool(_autoStartNextPomodoroKey) ?? true,
      'eSenseDeviceName': prefs.getString(_eSenseDeviceNameKey) ?? 'eSense-',
    };
  }

  /// Speichert alle übergebenen Einstellungen in SharedPreferences.
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pomodoroDurationKey, settings['pomodoroDuration']);
    await prefs.setInt(_shortBreakDurationKey, settings['shortBreakDuration']);
    await prefs.setInt(_longBreakDurationKey, settings['longBreakDuration']);
    await prefs.setInt(_sessionsBeforeLongBreakKey, settings['sessionsBeforeLongBreak']);
    await prefs.setBool(_autoStartNextPomodoroKey, settings['autoStartNextPomodoro']);
    await prefs.setString(_eSenseDeviceNameKey, settings['eSenseDeviceName']);
  }

  /// Aktualisiert die Pomodoro-Dauer.
  Future<void> updatePomodoroDuration(Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pomodoroDurationKey, duration.inMinutes);
  }

  /// Aktualisiert die Dauer für kurze Pausen.
  Future<void> updateShortBreakDuration(Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_shortBreakDurationKey, duration.inMinutes);
  }

  /// Aktualisiert die Dauer für lange Pausen.
  Future<void> updateLongBreakDuration(Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_longBreakDurationKey, duration.inMinutes);
  }

  /// Legt fest, nach wie vielen Sessions eine lange Pause stattfinden soll.
  Future<void> updateSessionsBeforeLongBreak(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionsBeforeLongBreakKey, count);
  }

  /// Aktiviert oder deaktiviert den automatischen Start der nächsten Pomodoro-Einheit.
  Future<void> updateAutoStartNextPomodoro(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoStartNextPomodoroKey, value);
  }

  /// Speichert den Namen des eSense-Geräts für die Verbindung.
  Future<void> updateESenseDeviceName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_eSenseDeviceNameKey, name);
  }
}
