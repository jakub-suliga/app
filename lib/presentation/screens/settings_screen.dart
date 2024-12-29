import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/settings/settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Zugriff auf SettingsCubit
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
                // eSense-Einstellungen
                const Text(
                  'eSense',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'eSense-Gerätename',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(
                    text: state.eSenseDeviceName,
                  ),
                  onChanged: (val) {
                    settingsCubit.setESenseDeviceName(val.trim());
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),

                // Aufgabenliste-Einstellungen
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

                // Tags
                ListTile(
                  title: const Text('Tags bearbeiten'),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    _showEditTagsDialog(context, state.tags);
                  },
                ),

                // Prioritäten
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dialog: Tags
  // ---------------------------------------------------------------------------

  void _showEditTagsDialog(BuildContext context, List<String> tags) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: _EditTagsSection(tags: tags),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Dialog: Priorities
  // ---------------------------------------------------------------------------

  void _showEditPrioritiesDialog(BuildContext context, List<String> priorities) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: MediaQuery.of(ctx).viewInsets,
          child: _EditPrioritiesSection(priorities: priorities),
        );
      },
    );
  }
}

// ============================================================================
// Tags-Bearbeitung
// ============================================================================
class _EditTagsSection extends StatefulWidget {
  final List<String> tags;

  const _EditTagsSection({required this.tags});

  @override
  State<_EditTagsSection> createState() => _EditTagsSectionState();
}

class _EditTagsSectionState extends State<_EditTagsSection> {
  late List<String> tags;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    tags = List<String>.from(widget.tags);
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
                    onPressed: () => _showEditTagDialog(context, tag),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      settingsCubit.removeTag(tag);
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
            onSubmitted: (_) => _addTag(settingsCubit),
          ),
        ),
        ElevatedButton(
          onPressed: () => _addTag(settingsCubit),
          child: const Text('Tag hinzufügen'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _addTag(SettingsCubit cubit) {
    final newTag = _controller.text.trim();
    if (newTag.isNotEmpty && !cubit.state.tags.contains(newTag)) {
      cubit.addTag(newTag);
      setState(() {
        tags.add(newTag);
      });
      _controller.clear();
    }
  }

  void _showEditTagDialog(BuildContext context, String oldTag) {
    final TextEditingController controller = TextEditingController(text: oldTag);
    final settingsCubit = context.read<SettingsCubit>();

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
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                final newTag = controller.text.trim();
                if (newTag.isNotEmpty && newTag != oldTag) {
                  settingsCubit.editTag(oldTag, newTag);
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

// ============================================================================
// Priorities-Bearbeitung
// ============================================================================
class _EditPrioritiesSection extends StatefulWidget {
  final List<String> priorities;

  const _EditPrioritiesSection({required this.priorities});

  @override
  State<_EditPrioritiesSection> createState() => _EditPrioritiesSectionState();
}

class _EditPrioritiesSectionState extends State<_EditPrioritiesSection> {
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
            // Wichtig: die Reihenfolge in SettingsCubit speichern
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
            decoration: const InputDecoration(hintText: 'Neuer Priorität-Name'),
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
