import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/settings/settings_cubit.dart';

/// Zeigt und verwaltet die Einstellungen für eSense und Pomodoro.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// Implementiert Eingabefelder und Regler für eSense- und Pomodoro-Einstellungen.
class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _deviceNameController;
  double _pomodoroMinutes = 25.0;
  double _shortBreakMinutes = 5.0;
  double _longBreakMinutes = 15.0;
  double _sessionsBeforeLongBreak = 4.0;
  bool _autoStartNextPomodoro = true;

  @override
  void initState() {
    super.initState();
    final settingsState = context.read<SettingsCubit>().state;
    _deviceNameController = TextEditingController(text: settingsState.eSenseDeviceName);
    _pomodoroMinutes = settingsState.pomodoroDuration.inMinutes.toDouble();
    _shortBreakMinutes = settingsState.shortBreakDuration.inMinutes.toDouble();
    _longBreakMinutes = settingsState.longBreakDuration.inMinutes.toDouble();
    _sessionsBeforeLongBreak = settingsState.sessionsBeforeLongBreak.toDouble();
    _autoStartNextPomodoro = settingsState.autoStartNextPomodoro;
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: BlocListener<SettingsCubit, SettingsState>(
          listener: (context, state) {
            if (state.status == SettingsStatus.error && state.errorMessage != null) {}
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.headphones, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'eSense-Einstellungen',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      BlocBuilder<SettingsCubit, SettingsState>(
                        builder: (context, state) {
                          return _buildConnectionStatus(state.isESenseConnected);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'eSense-Gerätename',
                          border: OutlineInputBorder(),
                        ),
                        controller: _deviceNameController,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text('Speichern & Verbinden'),
                              onPressed: () async {
                                await _saveAndConnectESense(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.timer, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Pomodoro-Einstellungen',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSlider(
                        label: 'Dauer einer Pomodoro-Einheit',
                        value: _pomodoroMinutes,
                        min: 1,
                        max: 99,
                        divisions: 98,
                        unit: 'Minuten',
                        onChanged: (double value) {
                          setState(() => _pomodoroMinutes = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildSlider(
                        label: 'Dauer einer kurzen Pause',
                        value: _shortBreakMinutes,
                        min: 1,
                        max: 99,
                        divisions: 98,
                        unit: 'Minuten',
                        onChanged: (double value) {
                          setState(() => _shortBreakMinutes = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildSlider(
                        label: 'Dauer einer langen Pause',
                        value: _longBreakMinutes,
                        min: 1,
                        max: 99,
                        divisions: 98,
                        unit: 'Minuten',
                        onChanged: (double value) {
                          setState(() => _longBreakMinutes = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildSlider(
                        label: 'Anzahl der Pomodoro-Einheiten vor einer langen Pause',
                        value: _sessionsBeforeLongBreak,
                        min: 1,
                        max: 99,
                        divisions: 98,
                        unit: '',
                        onChanged: (double value) {
                          setState(() => _sessionsBeforeLongBreak = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Automatisch nächste Pomodoro-Einheit starten'),
                        value: _autoStartNextPomodoro,
                        onChanged: (val) {
                          setState(() => _autoStartNextPomodoro = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text('Speichern'),
                              onPressed: () async {
                                await _savePomodoroSettings(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Speichert und verbindet das eSense-Gerät mit dem angegebenen Namen.
  Future<void> _saveAndConnectESense(BuildContext context) async {
    await context.read<SettingsCubit>().setESenseDeviceName(_deviceNameController.text.trim());
    await context.read<SettingsCubit>().connectESense();
  }

  /// Speichert die eingegebenen Pomodoro-Einstellungen im SettingsCubit.
  Future<void> _savePomodoroSettings(BuildContext context) async {
    final pomodoroMinutes = _pomodoroMinutes.toInt();
    final shortBreakMinutes = _shortBreakMinutes.toInt();
    final longBreakMinutes = _longBreakMinutes.toInt();
    final sessionsBeforeLongBreak = _sessionsBeforeLongBreak.toInt();
    if (pomodoroMinutes <= 0 ||
        shortBreakMinutes <= 0 ||
        longBreakMinutes <= 0 ||
        sessionsBeforeLongBreak <= 0) {
      return;
    }
    await context.read<SettingsCubit>().setPomodoroDuration(Duration(minutes: pomodoroMinutes));
    await context.read<SettingsCubit>().setShortBreakDuration(Duration(minutes: shortBreakMinutes));
    await context.read<SettingsCubit>().setLongBreakDuration(Duration(minutes: longBreakMinutes));
    await context.read<SettingsCubit>().setSessionsBeforeLongBreak(sessionsBeforeLongBreak);
    await context.read<SettingsCubit>().toggleAutoStartNextPomodoro(_autoStartNextPomodoro);
  }

  /// Zeigt den aktuellen Verbindungsstatus an, z. B. "Verbunden" oder "Nicht verbunden".
  Widget _buildConnectionStatus(bool isConnected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isConnected ? Icons.check_circle : Icons.cancel, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            isConnected ? 'Verbunden' : 'Nicht verbunden',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Erstellt einen Slider mit Label, Bereich und Einheit für die Pomodoro-Einstellungen.
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
        Text('$label: ${value.toInt()} $unit', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
}
