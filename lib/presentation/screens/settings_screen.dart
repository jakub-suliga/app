// lib/screens/settings_screen.dart

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
  String _tempName = ''; // Puffer für das Textfeld

  // Controller für Pomodoro-Einstellungen
  final TextEditingController _pomodoroController = TextEditingController();
  final TextEditingController _shortBreakController = TextEditingController();
  final TextEditingController _longBreakController = TextEditingController();
  final TextEditingController _sessionsBeforeLongBreakController =
      TextEditingController();
  bool _autoStartNextPomodoro = false;

  @override
  void initState() {
    super.initState();
    // Starte mit dem aktuellen Gerätenamen aus dem State
    final currentName = context.read<SettingsCubit>().state.eSenseDeviceName;
    _tempName = currentName;
    _deviceNameController = TextEditingController(text: currentName);

    // Initialisiere die Pomodoro-Controller mit den aktuellen Einstellungen
    final settings = context.read<SettingsCubit>().state;
    _pomodoroController.text = settings.pomodoroDuration.inMinutes.toString();
    _shortBreakController.text =
        settings.shortBreakDuration.inMinutes.toString();
    _longBreakController.text =
        settings.longBreakDuration.inMinutes.toString();
    _sessionsBeforeLongBreakController.text =
        settings.sessionsBeforeLongBreak.toString();
    _autoStartNextPomodoro = settings.autoStartNextPomodoro;
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _pomodoroController.dispose();
    _shortBreakController.dispose();
    _longBreakController.dispose();
    _sessionsBeforeLongBreakController.dispose();
    super.dispose();
  }

  // Methode zum Anzeigen des Dialogs zum Bearbeiten der Prioritäten
  void _showEditPrioritiesDialog(
      BuildContext context, List<String> priorities) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: EditPrioritiesSection(priorities: priorities),
        );
      },
    );
  }

  // Methode zum Anzeigen des Dialogs zum Bearbeiten der Pomodoro-Einstellungen
  void _showEditPomodoroSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Pomodoro-Einstellungen bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // Pomodoro-Dauer
                TextField(
                  controller: _pomodoroController,
                  decoration: const InputDecoration(
                    labelText: 'Dauer einer Pomodoro-Einheit (Minuten)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),

                // Kurze Pause
                TextField(
                  controller: _shortBreakController,
                  decoration: const InputDecoration(
                    labelText: 'Dauer einer kurzen Pause (Minuten)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),

                // Lange Pause
                TextField(
                  controller: _longBreakController,
                  decoration: const InputDecoration(
                    labelText: 'Dauer einer langen Pause (Minuten)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),

                // Anzahl der Sitzungen vor langer Pause
                TextField(
                  controller: _sessionsBeforeLongBreakController,
                  decoration: const InputDecoration(
                    labelText:
                        'Anzahl der Pomodoro-Einheiten vor einer langen Pause',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),

                // Automatisches Starten der nächsten Pomodoro-Einheit
                SwitchListTile(
                  title:
                      const Text('Automatisch nächste Pomodoro-Einheit starten'),
                  value: _autoStartNextPomodoro,
                  onChanged: (val) {
                    setState(() {
                      _autoStartNextPomodoro = val;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                // Validierung der Eingaben
                final pomodoroMinutes =
                    int.tryParse(_pomodoroController.text);
                final shortBreakMinutes =
                    int.tryParse(_shortBreakController.text);
                final longBreakMinutes = int.tryParse(_longBreakController.text);
                final sessionsBeforeLongBreak =
                    int.tryParse(_sessionsBeforeLongBreakController.text);

                if (pomodoroMinutes == null ||
                    shortBreakMinutes == null ||
                    longBreakMinutes == null ||
                    sessionsBeforeLongBreak == null ||
                    pomodoroMinutes <= 0 ||
                    shortBreakMinutes <= 0 ||
                    longBreakMinutes <= 0 ||
                    sessionsBeforeLongBreak <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Bitte geben Sie gültige Werte ein.')),
                  );
                  return;
                }

                // Aktualisiere die Einstellungen im Cubit
                final settingsCubit = context.read<SettingsCubit>();
                settingsCubit.setPomodoroDuration(
                    Duration(minutes: pomodoroMinutes));
                settingsCubit.setShortBreakDuration(
                    Duration(minutes: shortBreakMinutes));
                settingsCubit.setLongBreakDuration(
                    Duration(minutes: longBreakMinutes));
                settingsCubit.setSessionsBeforeLongBreak(
                    sessionsBeforeLongBreak);
                settingsCubit
                    .toggleAutoStartNextPomodoro(_autoStartNextPomodoro);

                // Zeige Bestätigung
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pomodoro-Einstellungen gespeichert.')),
                );

                Navigator.pop(ctx);
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
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

                // TextField NUR zur Eingabe. Änderung wird in _tempName gepuffert.
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'eSense-Gerätename',
                    border: OutlineInputBorder(),
                  ),
                  controller: _deviceNameController,
                  onChanged: (val) {
                    _tempName = val; // nur lokal speichern
                  },
                ),
                const SizedBox(height: 8),

                // Speichern-Button => erst DANN wird der Name ins State übernommen
                ElevatedButton(
                  onPressed: () {
                    settingsCubit.setESenseDeviceName(_tempName.trim());
                    // Option: Zeige SnackBar oder so
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'eSense-Gerätename gespeichert: "${_tempName.trim()}"',
                        ),
                      ),
                    );
                  },
                  child: const Text('Speichern'),
                ),
                const SizedBox(height: 16),

                const Divider(),
                // -------------------------------------------
                // Aufgabenliste-Einstellungen
                // -------------------------------------------
                const Text(
                  'Aufgabenliste',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SwitchListTile(
                  title: const Text('Erledigte Aufgaben anzeigen'),
                  value: state.showCompletedTasks,
                  onChanged: (val) {
                    settingsCubit.toggleShowCompletedTasks(val);
                  },
                ),
                const SizedBox(height: 8),

                // Prioritäten
                ListTile(
                  title: const Text('Prioritäten bearbeiten'),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    _showEditPrioritiesDialog(context, state.priorities);
                  },
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
                const SizedBox(height: 8),

                // Pomodoro-Dauer
                TextField(
                  controller: _pomodoroController,
                  decoration: const InputDecoration(
                    labelText: 'Dauer einer Pomodoro-Einheit (Minuten)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),

                // Kurze Pause
                TextField(
                  controller: _shortBreakController,
                  decoration: const InputDecoration(
                    labelText: 'Dauer einer kurzen Pause (Minuten)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),

                // Lange Pause
                TextField(
                  controller: _longBreakController,
                  decoration: const InputDecoration(
                    labelText: 'Dauer einer langen Pause (Minuten)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),

                // Anzahl der Sitzungen vor langer Pause
                TextField(
                  controller: _sessionsBeforeLongBreakController,
                  decoration: const InputDecoration(
                    labelText:
                        'Anzahl der Pomodoro-Einheiten vor einer langen Pause',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),

                // Automatisches Starten der nächsten Pomodoro-Einheit
                SwitchListTile(
                  title: const Text('Automatisch nächste Pomodoro-Einheit starten'),
                  value: _autoStartNextPomodoro,
                  onChanged: (val) {
                    setState(() {
                      _autoStartNextPomodoro = val;
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Speichern-Button für Pomodoro-Einstellungen
                ElevatedButton(
                  onPressed: () {
                    // Validierung der Eingaben
                    final pomodoroMinutes =
                        int.tryParse(_pomodoroController.text);
                    final shortBreakMinutes =
                        int.tryParse(_shortBreakController.text);
                    final longBreakMinutes =
                        int.tryParse(_longBreakController.text);
                    final sessionsBeforeLongBreak =
                        int.tryParse(_sessionsBeforeLongBreakController.text);

                    if (pomodoroMinutes == null ||
                        shortBreakMinutes == null ||
                        longBreakMinutes == null ||
                        sessionsBeforeLongBreak == null ||
                        pomodoroMinutes <= 0 ||
                        shortBreakMinutes <= 0 ||
                        longBreakMinutes <= 0 ||
                        sessionsBeforeLongBreak <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Bitte geben Sie gültige Werte ein.')),
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
                          content: Text('Pomodoro-Einstellungen gespeichert.')),
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
}

/// Benutzerdefinierte Klasse zum Bearbeiten der Prioritäten
class EditPrioritiesSection extends StatefulWidget {
  final List<String> priorities;

  const EditPrioritiesSection({required this.priorities, Key? key})
      : super(key: key);

  @override
  State<EditPrioritiesSection> createState() => _EditPrioritiesSectionState();
}

class _EditPrioritiesSectionState extends State<EditPrioritiesSection> {
  late List<String> priorities;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    priorities = List<String>.from(widget.priorities);
  }

  @override
  Widget build(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Prioritäten bearbeiten',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ReorderableListView(
          shrinkWrap: true,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex--;
              final item = priorities.removeAt(oldIndex);
              priorities.insert(newIndex, item);
            });
            // Wichtig: Reihenfolge in SettingsCubit speichern
            settingsCubit.reorderPriorities(oldIndex, newIndex);
          },
          children: [
            for (int index = 0; index < priorities.length; index++)
              ListTile(
                key: ValueKey(priorities[index]),
                title: Text(priorities[index]),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _showEditPriorityDialog(context, priorities[index]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        settingsCubit.removePriority(priorities[index]);
                        setState(() {
                          priorities.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Neue Priorität',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _addPriority(settingsCubit),
          ),
        ),
        ElevatedButton(
          onPressed: () => _addPriority(settingsCubit),
          child: const Text('Priorität hinzufügen'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _addPriority(SettingsCubit cubit) {
    final newPriority = _controller.text.trim();
    if (newPriority.isNotEmpty && !cubit.state.priorities.contains(newPriority)) {
      cubit.addPriority(newPriority);
      setState(() {
        priorities.add(newPriority);
      });
      _controller.clear();
    }
  }

  void _showEditPriorityDialog(BuildContext context, String oldPriority) {
    final TextEditingController controller =
        TextEditingController(text: oldPriority);
    final settingsCubit = context.read<SettingsCubit>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Priorität bearbeiten'),
          content: TextField(
            controller: controller,
            decoration:
                const InputDecoration(hintText: 'Neuer Priorität-Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                final newPriority = controller.text.trim();
                if (newPriority.isNotEmpty && newPriority != oldPriority) {
                  settingsCubit.editPriority(oldPriority, newPriority);
                  Navigator.pop(ctx);
                  setState(() {
                    final index = priorities.indexOf(oldPriority);
                    if (index != -1) {
                      priorities[index] = newPriority;
                    }
                  });
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }
}
