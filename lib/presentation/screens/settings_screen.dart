// lib/presentation/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/settings/settings_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _deviceNameController;

  // State-Variablen für Pomodoro-Einstellungen
  double _pomodoroMinutes = 25.0; // Standardwert
  double _shortBreakMinutes = 5.0; // Standardwert
  double _longBreakMinutes = 15.0; // Standardwert
  double _sessionsBeforeLongBreak = 4.0; // Standardwert
  bool _autoStartNextPomodoro = false;

  @override
  void initState() {
    super.initState();
    // Starte mit dem aktuellen Gerätenamen aus dem State
    final currentName = context.read<SettingsCubit>().state.eSenseDeviceName;
    _deviceNameController = TextEditingController(text: currentName);

    // Initialisiere die Pomodoro-Settings mit den aktuellen Einstellungen
    final settings = context.read<SettingsCubit>().state;
    _pomodoroMinutes = settings.pomodoroDuration.inMinutes.toDouble();
    _shortBreakMinutes = settings.shortBreakDuration.inMinutes.toDouble();
    _longBreakMinutes = settings.longBreakDuration.inMinutes.toDouble();
    _sessionsBeforeLongBreak = settings.sessionsBeforeLongBreak.toDouble();
    _autoStartNextPomodoro = settings.autoStartNextPomodoro;
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------------------------------------------
                // eSense-Einstellungen
                // -------------------------------------------
                const Text(
                  'eSense',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Verbindungstatus anzeigen
                _buildConnectionStatus(state.isESenseConnected),

                const SizedBox(height: 8),

                // TextField zur Eingabe des eSense-Gerätenamens
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'eSense-Gerätename',
                    border: OutlineInputBorder(),
                  ),
                  controller: _deviceNameController,
                  onChanged: (val) {
                    // Keine unmittelbare Veränderung hier
                  },
                ),
                const SizedBox(height: 8),

                // Speichern & Verbinden-Button für eSense-Einstellungen
                ElevatedButton(
                  onPressed: () async {
                    // Aktualisiere den Gerätenamen
                    settingsCubit.setESenseDeviceName(
                        _deviceNameController.text.trim());

                    // Versuche, die Verbindung herzustellen
                    await settingsCubit.connectESense();

                    // Zeige SnackBar oder andere Bestätigung
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.isESenseConnected
                              ? 'eSense-Gerätename gespeichert und verbunden: "${_deviceNameController.text.trim()}"'
                              : 'eSense-Gerätename gespeichert, Verbindung fehlgeschlagen.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Speichern & Verbinden'),
                ),
                const SizedBox(height: 16),

                const Divider(),
                // -------------------------------------------
                // Pomodoro-Einstellungen
                // -------------------------------------------
                const Text(
                  'Pomodoro-Einstellungen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Pomodoro-Dauer mit Slider
                _buildSlider(
                  label: 'Dauer einer Pomodoro-Einheit',
                  value: _pomodoroMinutes,
                  min: 1,
                  max: 99,
                  divisions: 98,
                  unit: 'Minuten',
                  onChanged: (double value) {
                    setState(() {
                      _pomodoroMinutes = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Dauer einer kurzen Pause mit Slider
                _buildSlider(
                  label: 'Dauer einer kurzen Pause',
                  value: _shortBreakMinutes,
                  min: 1,
                  max: 99,
                  divisions: 98,
                  unit: 'Minuten',
                  onChanged: (double value) {
                    setState(() {
                      _shortBreakMinutes = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Dauer einer langen Pause mit Slider
                _buildSlider(
                  label: 'Dauer einer langen Pause',
                  value: _longBreakMinutes,
                  min: 1,
                  max: 99,
                  divisions: 98,
                  unit: 'Minuten',
                  onChanged: (double value) {
                    setState(() {
                      _longBreakMinutes = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Anzahl der Pomodoro-Einheiten vor einer langen Pause mit Slider
                _buildSlider(
                  label: 'Anzahl der Pomodoro-Einheiten vor einer langen Pause',
                  value: _sessionsBeforeLongBreak,
                  min: 1,
                  max: 99,
                  divisions: 98,
                  unit: '',
                  onChanged: (double value) {
                    setState(() {
                      _sessionsBeforeLongBreak = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Automatisches Starten der nächsten Pomodoro-Einheit
                SwitchListTile(
                  title: const Text(
                      'Automatisch nächste Pomodoro-Einheit starten'),
                  value: _autoStartNextPomodoro,
                  onChanged: (val) {
                    setState(() {
                      _autoStartNextPomodoro = val;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Speichern-Button für Pomodoro-Einstellungen
                ElevatedButton(
                  onPressed: () {
                    // Validierung der Eingaben
                    final pomodoroMinutes = _pomodoroMinutes.toInt(); // Direkt vom Slider
                    final shortBreakMinutes = _shortBreakMinutes.toInt(); // Direkt vom Slider
                    final longBreakMinutes = _longBreakMinutes.toInt(); // Direkt vom Slider
                    final sessionsBeforeLongBreak = _sessionsBeforeLongBreak.toInt(); // Direkt vom Slider

                    if (pomodoroMinutes <= 0 ||
                        shortBreakMinutes <= 0 ||
                        longBreakMinutes <= 0 ||
                        sessionsBeforeLongBreak <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Bitte geben Sie gültige Werte ein.')),
                      );
                      return;
                    }

                    // Aktualisiere die Einstellungen im Cubit
                    settingsCubit.setPomodoroDuration(
                        Duration(minutes: pomodoroMinutes));
                    settingsCubit.setShortBreakDuration(
                        Duration(minutes: shortBreakMinutes));
                    settingsCubit.setLongBreakDuration(
                        Duration(minutes: longBreakMinutes));
                    settingsCubit.setSessionsBeforeLongBreak(
                        sessionsBeforeLongBreak);
                    settingsCubit.toggleAutoStartNextPomodoro(
                        _autoStartNextPomodoro);

                    // Zeige Bestätigung
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Pomodoro-Einstellungen gespeichert.')),
                    );
                  },
                  child: const Text('Speichern'),
                ),

                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Methode zur Erstellung eines Sliders mit einem Label
  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${value.toInt()} $unit',
          style: const TextStyle(fontSize: 16),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: '${value.toInt()}',
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Methode zur Anzeige des Verbindungstatus
  Widget _buildConnectionStatus(bool isConnected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isConnected ? 'Verbunden' : 'Nicht verbunden',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
