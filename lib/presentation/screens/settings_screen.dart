// lib/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/tasks/tasks_settings_cubit.dart';
import '../../logic/pomodoro/pomodoro_cubit.dart';
import '../../logic/theme/theme_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Zugriff auf die benötigten Cubits
    final tasksSettingsCubit = context.read<TasksSettingsCubit>();
    final pomodoroCubit = context.read<PomodoroCubit>();
    final themeCubit = context.read<ThemeCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Allgemeine Einstellungen
            const Text(
              'Allgemein',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                const Text('Dark Mode'),
                const Spacer(),
                BlocBuilder<ThemeCubit, ThemeState>(
                  builder: (context, state) {
                    final isDarkMode = state.themeData.brightness == Brightness.dark;
                    return Switch(
                      value: isDarkMode,
                      onChanged: (value) {
                        themeCubit.toggleTheme();
                      },
                    );
                  },
                ),
              ],
            ),
            const Divider(),

            // Aufgabenliste-Einstellungen
            const Text(
              'Aufgabenliste',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            BlocBuilder<TasksSettingsCubit, TasksSettingsState>(
              builder: (context, state) {
                return Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Erledigte Aufgaben anzeigen'),
                      value: state.showCompletedTasks,
                      onChanged: (val) {
                        tasksSettingsCubit.toggleShowCompletedTasks(val);
                      },
                    ),
                    ListTile(
                      title: const Text('Tags bearbeiten'),
                      trailing: const Icon(Icons.edit),
                      onTap: () {
                        _showEditTagsDialog(context, state.tags);
                      },
                    ),
                    ListTile(
                      title: const Text('Prioritäten bearbeiten'),
                      trailing: const Icon(Icons.edit),
                      onTap: () {
                        _showEditPrioritiesDialog(context, state.priorities);
                      },
                    ),
                  ],
                );
              },
            ),
            const Divider(),

            // Pomodoro-Einstellungen
            const Text(
              'Pomodoro',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            BlocBuilder<PomodoroCubit, PomodoroState>(
              builder: (context, state) {
                final pomodoroMin = pomodoroCubit.pomodoroDuration;
                final shortBreakMin = pomodoroCubit.shortBreak;
                final longBreakMin = pomodoroCubit.longBreak;

                final pomodoroCtrl = TextEditingController(text: pomodoroMin.toString());
                final shortCtrl = TextEditingController(text: shortBreakMin.toString());
                final longCtrl = TextEditingController(text: longBreakMin.toString());

                return Column(
                  children: [
                    _buildNumberField(
                      context,
                      'Pomodoro (Min)',
                      pomodoroCtrl,
                      (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null) {
                          pomodoroCubit.setPomodoroDuration(parsed);
                        }
                      },
                    ),
                    _buildNumberField(
                      context,
                      'Kurze Pause (Min)',
                      shortCtrl,
                      (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null) {
                          pomodoroCubit.setShortBreak(parsed);
                        }
                      },
                    ),
                    _buildNumberField(
                      context,
                      'Lange Pause (Min)',
                      longCtrl,
                      (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null) {
                          pomodoroCubit.setLongBreak(parsed);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }

  /// Erstellt ein Textfeld für ganze Zahlen mit einem Label
  Widget _buildNumberField(
    BuildContext context,
    String label,
    TextEditingController controller,
    Function(String) onSaved,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(label),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true, // Reduziert die Höhe des Textfelds
                contentPadding: EdgeInsets.all(8),
              ),
              onSubmitted: (val) {
                if (val.isNotEmpty) {
                  onSaved(val);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog zum Bearbeiten der Tags
  void _showEditTagsDialog(BuildContext context, List<String> tags) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: EditTagsSection(tags: tags),
        );
      },
    );
  }

  /// Dialog zum Bearbeiten der Prioritäten
  void _showEditPrioritiesDialog(BuildContext context, List<String> priorities) {
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
}

/// Widget für die Bearbeitung der Tags innerhalb des SettingsScreen
class EditTagsSection extends StatefulWidget {
  final List<String> tags;

  const EditTagsSection({super.key, required this.tags});

  @override
  State<EditTagsSection> createState() => _EditTagsSectionState();
}

class _EditTagsSectionState extends State<EditTagsSection> {
  late List<String> tags;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    tags = List<String>.from(widget.tags);
  }

  @override
  Widget build(BuildContext context) {
    final tasksSettingsCubit = context.read<TasksSettingsCubit>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Tags bearbeiten',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: tags.length,
          itemBuilder: (context, index) {
            final tag = tags[index];
            return ListTile(
              title: Text(tag),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _showEditTagDialog(context, tag);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      tasksSettingsCubit.removeTag(tag);
                      setState(() {
                        tags.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Neues Tag',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (val) {
              _addTag(tasksSettingsCubit);
            },
          ),
        ),
        ElevatedButton(
          onPressed: () {
            _addTag(tasksSettingsCubit);
          },
          child: const Text('Tag hinzufügen'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _addTag(TasksSettingsCubit cubit) {
    final newTag = _controller.text.trim();
    if (newTag.isNotEmpty && !cubit.state.tags.contains(newTag)) {
      cubit.addTag(newTag);
      setState(() {
        tags.add(newTag);
        _controller.clear();
      });
    }
  }

  void _showEditTagDialog(BuildContext context, String oldTag) {
    final TextEditingController controller = TextEditingController(text: oldTag);
    final tasksSettingsCubit = context.read<TasksSettingsCubit>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Tag bearbeiten'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Neuer Tag-Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                final newTag = controller.text.trim();
                if (newTag.isNotEmpty && newTag != oldTag) {
                  tasksSettingsCubit.editTag(oldTag, newTag);
                  Navigator.pop(ctx);
                  setState(() {
                    final index = tags.indexOf(oldTag);
                    if (index != -1) {
                      tags[index] = newTag;
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

/// Widget für die Bearbeitung der Prioritäten innerhalb des SettingsScreen
class EditPrioritiesSection extends StatefulWidget {
  final List<String> priorities;

  const EditPrioritiesSection({super.key, required this.priorities});

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
    final tasksSettingsCubit = context.read<TasksSettingsCubit>();

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
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final item = priorities.removeAt(oldIndex);
              priorities.insert(newIndex, item);
              tasksSettingsCubit.reorderPriorities(oldIndex, newIndex);
            });
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
                      onPressed: () {
                        _showEditPriorityDialog(context, priorities[index]);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        tasksSettingsCubit.removePriority(priorities[index]);
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
            onSubmitted: (val) {
              _addPriority(tasksSettingsCubit);
            },
          ),
        ),
        ElevatedButton(
          onPressed: () {
            _addPriority(tasksSettingsCubit);
          },
          child: const Text('Priorität hinzufügen'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _addPriority(TasksSettingsCubit cubit) {
    final newPriority = _controller.text.trim();
    if (newPriority.isNotEmpty && !cubit.state.priorities.contains(newPriority)) {
      cubit.addPriority(newPriority);
      setState(() {
        priorities.add(newPriority);
        _controller.clear();
      });
    }
  }

  void _showEditPriorityDialog(BuildContext context, String oldPriority) {
    final TextEditingController controller = TextEditingController(text: oldPriority);
    final tasksSettingsCubit = context.read<TasksSettingsCubit>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Priorität bearbeiten'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Neuer Priorität-Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                final newPriority = controller.text.trim();
                if (newPriority.isNotEmpty && newPriority != oldPriority) {
                  tasksSettingsCubit.editPriority(oldPriority, newPriority);
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
