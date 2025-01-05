// lib/presentation/screens/task_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/tasks/tasks_cubit.dart';
import '../../../data/models/task_model.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart'; // Importiere die festen Prioritäten
import 'package:uuid/uuid.dart'; // Für eindeutige IDs

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        List<TaskModel> activeTasks = [];
        List<TaskModel> completedTasks = [];
        if (state is TasksLoaded) {
          activeTasks = state.activeTasks;
          completedTasks = state.completedTasks;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Aufgabenliste'),
            // **Entfernung des Buttons aus dem AppBar**
            // actions: [
            //   IconButton(
            //     icon: const Icon(Icons.refresh),
            //     onPressed: () {
            //       context.read<TasksCubit>().loadTasks();
            //     },
            //     tooltip: 'Aufgaben aktualisieren',
            //   ),
            // ],
          ),
          body: (state is TasksLoading)
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Aktive Aufgaben
                      const Text(
                        'Aktive Aufgaben',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      activeTasks.isEmpty
                          ? const Text('Keine aktiven Aufgaben.')
                          : Column(
                              children: activeTasks.map((task) => _buildTaskItem(context, task)).toList(),
                            ),
                      const SizedBox(height: 20),
                      // Erledigte Aufgaben
                      const Text(
                        'Erledigte Aufgaben',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      completedTasks.isEmpty
                          ? const Text('Keine erledigten Aufgaben.')
                          : Column(
                              children: completedTasks.map((task) => _buildCompletedTaskItem(context, task)).toList(),
                            ),
                    ],
                  ),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddTaskDialog(context),
            child: const Icon(Icons.add),
            tooltip: 'Neue Aufgabe hinzufügen',
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(BuildContext context, TaskModel task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: SizedBox(
          width: 120, // Angepasste Breite für Label und Checkbox
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label "Erledigt?:"
              const Text(
                'Erledigt?:',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 5),
              // Checkbox
              Transform.scale(
                scale: 0.8, // Verkleinert die Checkbox auf 80%
                child: Checkbox(
                  value: task.isCompleted,
                  onChanged: (val) {
                    if (val != null && val) {
                      context.read<TasksCubit>().markTaskAsCompleted(task.id);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        title: GestureDetector(
          onTap: () => _editTask(context, task),
          child: Text(
            task.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis, // Verhindert Überlauf
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.description,
              overflow: TextOverflow.ellipsis, // Verhindert Überlauf
            ),
            if (task.endDate != null)
              Text(
                'Fällig bis: ${DateFormat.yMd().format(task.endDate!)}',
                overflow: TextOverflow.ellipsis, // Verhindert Überlauf
              ),
            Text(
              'Priorität: ${task.priority}',
              overflow: TextOverflow.ellipsis, // Verhindert Überlauf
            ),
            Text(
              'Verbleibende Dauer: ${_formatDuration(task.duration)}',
              overflow: TextOverflow.ellipsis, // Verhindert Überlauf
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bearbeiten-Icon (Stift)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () => _editTask(context, task),
              tooltip: 'Aufgabe bearbeiten',
            ),
            // Löschen-Icon (Müll)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () {
                // Bestätigungsdialog vor dem Löschen
                _confirmDelete(context, task);
              },
              tooltip: 'Aufgabe löschen',
            ),
          ],
        ),
        onTap: () => _editTask(context, task),
      ),
    );
  }

  Widget _buildCompletedTaskItem(BuildContext context, TaskModel task) {
    return Card(
      color: Colors.grey.shade200,
      child: ListTile(
        title: Text(
          task.title,
          style: const TextStyle(decoration: TextDecoration.lineThrough),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.description,
              overflow: TextOverflow.ellipsis, // Verhindert Überlauf
            ),
            if (task.endDate != null)
              Text(
                'Fällig bis: ${DateFormat.yMd().format(task.endDate!)}',
                overflow: TextOverflow.ellipsis, // Verhindert Überlauf
              ),
            Text(
              'Priorität: ${task.priority}',
              overflow: TextOverflow.ellipsis, // Verhindert Überlauf
            ),
            Text(
              'Dauer: ${_formatDuration(task.duration)}',
              overflow: TextOverflow.ellipsis, // Verhindert Überlauf
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.undo, color: Colors.blue, size: 20),
          onPressed: () {
            context.read<TasksCubit>().restoreTask(task.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Aufgabe "${task.title}" wiederhergestellt.')),
            );
          },
          tooltip: 'Aufgabe wiederherstellen',
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  void _editTask(BuildContext context, TaskModel task) {
    // Öffne den TaskDialog mit der bestehenden Aufgabe
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

  void _showAddTaskDialog(BuildContext context) {
    // Öffne den TaskDialog ohne eine bestehende Aufgabe
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
    // Initialisiere die Felder entweder mit den bestehenden Werten oder mit Standardwerten
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

              // Hinzufügen des Labels "Aufgabenlänge:" in normaler Schrift
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Aufgabenlänge:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal, // Normaler Schriftstil
                  ),
                ),
              ),
              const SizedBox(height: 5),

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
      // Da die App bereits auf Deutsch lokalisiert ist, ist keine weitere Anpassung erforderlich
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
          id: const Uuid().v4(),
          title: _title,
          description: _description,
          endDate: _endDate,
          priority: _priority,
          duration: duration,
          isCompleted: false,
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
