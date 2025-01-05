// lib/screens/tasks_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/tasks/tasks_cubit.dart';
import '../../../data/models/task_model.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart'; // Importieren Sie die festen Prioritäten

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String searchQuery = '';
  String selectedPrio = 'Alle';

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
    // Suche nach Titel
    if (searchQuery.isNotEmpty) {
      tasks = tasks.where((t) => t.title.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }
    // Filter nach Priorität
    if (selectedPrio != 'Alle') {
      tasks = tasks.where((t) => t.priority == selectedPrio).toList();
    }
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
            items: [
              const DropdownMenuItem(value: 'Alle', child: Text('Alle')),
              ...AppConstants.fixedPriorities.map((prio) => DropdownMenuItem(
                    value: prio,
                    child: Text(prio),
                  )),
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
    // Öffnen Sie den TaskDialog ohne eine bestehende Aufgabe
    showDialog(
      context: context,
      builder: (context) => const TaskDialog(),
    );
  }
}

/// TaskDialog Widget für Hinzufügen und Bearbeiten von Aufgaben
class TaskDialog extends StatefulWidget {
  final TaskModel? task; // Optional: Aufgabe zum Bearbeiten

  const TaskDialog({super.key, this.task});

  @override
  _TaskDialogState createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _title;
  late String _description;
  DateTime? _endDate;
  late String _priority;
  late int _durationHours;
  late int _durationMinutes;

  @override
  void initState() {
    super.initState();
    // Initialisieren Sie die Felder entweder mit den bestehenden Werten oder mit Standardwerten
    if (widget.task != null) {
      _title = widget.task!.title;
      _description = widget.task!.description;
      _endDate = widget.task!.endDate;
      _priority = widget.task!.priority;
      _durationHours = widget.task!.duration.inHours;
      _durationMinutes = widget.task!.duration.inMinutes.remainder(60);
    } else {
      _title = '';
      _description = '';
      _endDate = null;
      _priority = AppConstants.fixedPriorities[1]; // Standardpriorität: Mittel
      _durationHours = 0;
      _durationMinutes = 25; // Standard-Pomodoro-Dauer
    }
  }

  @override
  Widget build(BuildContext context) {
    // Da die Prioritäten fix sind, verwenden wir sie direkt aus AppConstants
    final List<String> priorities = AppConstants.fixedPriorities;

    return AlertDialog(
      title: Text(widget.task == null ? 'Neue Aufgabe erstellen' : 'Aufgabe bearbeiten'),
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
                initialValue: _title,
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
                initialValue: _description,
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
              DropdownButtonFormField<String>(
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
                validator: (value) =>
                    value == null || value.isEmpty ? 'Bitte wählen Sie eine Priorität aus.' : null,
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
                      initialValue: _durationHours.toString(),
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
                      initialValue: _durationMinutes.toString(),
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
          child: Text(widget.task == null ? 'Erstellen' : 'Speichern'),
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final duration = Duration(
        hours: _durationHours,
        minutes: _durationMinutes,
      );

      if (widget.task == null) {
        // Neue Aufgabe erstellen
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
      } else {
        // Bestehende Aufgabe aktualisieren
        final updatedTask = widget.task!.copyWith(
          title: _title,
          description: _description,
          endDate: _endDate,
          priority: _priority,
          duration: duration,
        );

        context.read<TasksCubit>().updateTask(updatedTask);
        Navigator.of(context).pop();
      }
    }
  }
}

/// TaskList Widget
class TaskList extends StatelessWidget {
  const TaskList({super.key});

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
                    value: false, // Da wir `isDone` entfernt haben
                    onChanged: (val) {
                      // Aufgabe entfernen statt aktualisieren
                      context.read<TasksCubit>().removeTask(task.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Aufgabe "${task.title}" entfernt.')),
                      );
                    },
                  ),
                  title: GestureDetector(
                    onTap: () => _editTask(context, task),
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.description),
                      if (task.endDate != null)
                        Text('Fällig bis: ${DateFormat.yMd().format(task.endDate!)}'),
                      Text('Priorität: ${task.priority}'),
                      Text('Verbleibende Dauer: ${_formatDuration(task.duration)}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bearbeiten-Icon (Stift)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editTask(context, task),
                        tooltip: 'Aufgabe bearbeiten',
                      ),
                      // Löschen-Icon (Müll)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Bestätigungsdialog vor dem Löschen
                          _confirmDelete(context, task);
                        },
                        tooltip: 'Aufgabe löschen',
                      ),
                    ],
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
    // Öffnen Sie den TaskDialog mit der bestehenden Aufgabe
    showDialog(
      context: context,
      builder: (context) => TaskDialog(task: task),
    );
  }

  void _confirmDelete(BuildContext context, TaskModel task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aufgabe löschen'),
        content: Text('Möchten Sie die Aufgabe "${task.title}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TasksCubit>().removeTask(task.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Aufgabe "${task.title}" gelöscht.')),
              );
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
