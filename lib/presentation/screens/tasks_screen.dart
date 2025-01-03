// lib/screens/tasks_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/tasks/tasks_cubit.dart';
import '../../../data/models/task_model.dart';
import 'package:intl/intl.dart';
import '../../logic/settings/settings_cubit.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String searchQuery = '';
  String selectedPrio = 'Alle';
  // List<String> selectedTags = []; // Entfernt

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        List<TaskModel> tasks = [];
        if (state is TasksLoaded) {
          tasks = state.tasks;
          tasks = _applyFilters(tasks);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Aufgabenliste'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _openSearch,
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _openFilterDialog,
              ),
            ],
          ),
          body: (state is TasksLoading)
              ? const Center(child: CircularProgressIndicator())
              : TaskList(), // Verwenden Sie das separate TaskList-Widget
          floatingActionButton: FloatingActionButton(
            onPressed: _createTask,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  List<TaskModel> _applyFilters(List<TaskModel> tasks) {
    // Search by title
    if (searchQuery.isNotEmpty) {
      tasks = tasks.where((t) => t.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }
    // Filter by priority
    if (selectedPrio != 'Alle') {
      tasks = tasks.where((t) => t.priority == selectedPrio).toList();
    }
    // Filter by tags - Entfernt
    /*
    if (selectedTags.isNotEmpty) {
      tasks = tasks.where((t) {
        for (final tag in selectedTags) {
          if (t.tags.contains(tag)) return true;
        }
        return false;
      }).toList();
    }
    */
    return tasks;
  }

  void _openSearch() async {
    // Einfaches Dialog
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String tmp = searchQuery;
        return AlertDialog(
          title: const Text('Aufgaben durchsuchen'),
          content: TextField(
            decoration: const InputDecoration(hintText: 'Suchbegriff'),
            onChanged: (val) => tmp = val,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
            TextButton(onPressed: () => Navigator.pop(ctx, tmp), child: const Text('Ok')),
          ],
        );
      },
    );
    if (result != null) {
      setState(() {
        searchQuery = result;
      });
    }
  }

  void _openFilterDialog() async {
    // Filter nach Priorität
    await showDialog(
      context: context,
      builder: (ctx) {
        String selected = selectedPrio; // Kopie
        return AlertDialog(
          title: const Text('Filter'),
          content: DropdownButton<String>(
            value: selected,
            items: const [
              DropdownMenuItem(value: 'Alle', child: Text('Alle')),
              DropdownMenuItem(value: 'Hoch', child: Text('Hoch')),
              DropdownMenuItem(value: 'Normal', child: Text('Normal')),
              DropdownMenuItem(value: 'Niedrig', child: Text('Niedrig')),
            ],
            onChanged: (val) {
              selected = val ?? 'Alle';
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    ).then((value) {
      if (value != null) {
        setState(() => selectedPrio = value);
      }
    });
  }

  void _createTask() {
    // Öffnen Sie den AddTaskDialog
    showDialog(
      context: context,
      builder: (context) => const AddTaskDialog(),
    );
  }

  void _editTask(TaskModel task) {
    // Implementieren Sie das Bearbeiten einer Aufgabe hier, falls gewünscht
    // Beispielsweise durch Öffnen eines ähnlichen Dialogs wie AddTaskDialog mit vorgefüllten Werten
  }
}

/// AddTaskDialog Widget
class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({Key? key}) : super(key: key);

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();

  String _title = '';
  String _description = '';
  DateTime? _endDate;
  String _priority = 'Normal'; // Standardpriorität
  int _durationHours = 0;
  int _durationMinutes = 25; // Standard-Pomodoro-Dauer

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final priorities = settingsState.priorities; // Annahme: Prioritäten sind Strings

    return AlertDialog(
      title: const Text('Neue Aufgabe erstellen'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Titel
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Titel ist erforderlich.' : null,
                onSaved: (value) => _title = value!,
              ),
              const SizedBox(height: 10),
              
              // Beschreibung
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onSaved: (value) => _description = value ?? '',
              ),
              const SizedBox(height: 10),
              
              // Enddatum
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _endDate == null
                          ? 'Kein Enddatum ausgewählt.'
                          : 'Enddatum: ${DateFormat.yMd().format(_endDate!)}',
                    ),
                  ),
                  TextButton(
                    onPressed: _pickEndDate,
                    child: const Text('Enddatum wählen'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Priorität
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Priorität',
                        border: OutlineInputBorder(),
                      ),
                      value: _priority,
                      items: priorities.map((priority) {
                        return DropdownMenuItem<String>(
                          value: priority,
                          child: Text(priority),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _priority = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: _addNewPriority,
                    child: const Text('Priorität hinzufügen'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dauer
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Stunden',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: '0',
                      onSaved: (value) => _durationHours = int.tryParse(value!) ?? 0,
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        if (int.tryParse(value) == null) return 'Ungültige Zahl';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Minuten',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: '25',
                      onSaved: (value) => _durationMinutes = int.tryParse(value!) ?? 25,
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        if (int.tryParse(value) == null) return 'Ungültige Zahl';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Erstellen'),
        ),
      ],
    );
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _addNewPriority() async {
    final TextEditingController _priorityController = TextEditingController();

    final newPriority = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neue Priorität hinzufügen'),
        content: TextField(
          controller: _priorityController,
          decoration: const InputDecoration(
            labelText: 'Priorität',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = _priorityController.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(context).pop(value);
              }
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );

    if (newPriority != null && newPriority.isNotEmpty) {
      context.read<SettingsCubit>().addPriority(newPriority);
      setState(() {
        _priority = newPriority;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final duration = Duration(
        hours: _durationHours,
        minutes: _durationMinutes,
      );

      final newTask = TaskModel(
        id: UniqueKey().toString(),
        title: _title,
        description: _description,
        endDate: _endDate,
        priority: _priority,
        duration: duration,
      );

      context.read<TasksCubit>().addTask(newTask);
      Navigator.of(context).pop();
    }
  }
}

/// TaskList Widget
class TaskList extends StatelessWidget {
  const TaskList({Key? key}) : super(key: key);

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        if (state is TasksLoaded) {
          final tasks = state.tasks;
          if (tasks.isEmpty) {
            return const Center(child: Text('Keine Aufgaben vorhanden.'));
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                child: ListTile(
                  leading: Checkbox(
                    value: task.isDone,
                    onChanged: (val) {
                      // Abgehakt => Cubit: updateTask
                      final updatedTask = task.copyWith(isDone: val ?? false);
                      context.read<TasksCubit>().updateTask(updatedTask);
                    },
                  ),
                  title: GestureDetector(
                    onTap: () => _editTask(context, task),
                    child: Text(task.title),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.description),
                      if (task.endDate != null)
                        Text('Enddatum: ${DateFormat.yMd().format(task.endDate!)}'),
                      Text('Priorität: ${task.priority}'),
                      Text('Dauer: ${_formatDuration(task.duration)}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      context.read<TasksCubit>().removeTask(task.id);
                    },
                  ),
                ),
              );
            },
          );
        }

        if (state is TasksLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TasksError) {
          return Center(child: Text(state.message));
        }

        return const SizedBox.shrink();
      },
    );
  }

  void _editTask(BuildContext context, TaskModel task) {
    // Implementieren Sie das Bearbeiten einer Aufgabe hier, falls gewünscht
    // Beispielsweise durch Öffnen eines ähnlichen Dialogs wie AddTaskDialog mit vorgefüllten Werten
  }
}
