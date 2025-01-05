import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/task_model.dart';
import '../../../logic/tasks/tasks_cubit.dart';
import '../../core/constants.dart';

/// Zeigt eine Liste von aktiven und erledigten Aufgaben an.
/// Ermöglicht das Erstellen, Bearbeiten und Löschen von Aufgaben.
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
        if (state is TasksLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Aufgabenliste'),
              centerTitle: true,
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.task_alt), text: 'Aktiv'),
                  Tab(icon: Icon(Icons.done_all), text: 'Erledigt'),
                ],
              ),
            ),
            body: TabBarView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildActiveTasks(context, activeTasks),
                _buildCompletedTasks(context, completedTasks),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddTaskDialog(context),
              child: const Icon(Icons.add),
              tooltip: 'Neue Aufgabe hinzufügen',
            ),
          ),
        );
      },
    );
  }

  /// Zeigt eine Liste aktiver Aufgaben oder einen Hinweis, falls keine vorhanden sind.
  Widget _buildActiveTasks(BuildContext context, List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text('Keine aktiven Aufgaben.', style: TextStyle(fontSize: 16)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: tasks.length,
      physics: const BouncingScrollPhysics(),
      separatorBuilder: (context, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskItem(context, task);
      },
    );
  }

  /// Zeigt eine Liste erledigter Aufgaben oder einen Hinweis, falls keine vorhanden sind.
  Widget _buildCompletedTasks(BuildContext context, List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text('Keine erledigten Aufgaben.', style: TextStyle(fontSize: 16)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: tasks.length,
      physics: const BouncingScrollPhysics(),
      separatorBuilder: (context, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildCompletedTaskItem(context, task);
      },
    );
  }

  /// Erstellt das Layout für eine aktive Aufgabe.
  Widget _buildTaskItem(BuildContext context, TaskModel task) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: ListTile(
        leading: _buildCheckBox(context, task),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: _buildTaskSubInfo(task),
        trailing: _buildTrailingIcons(context, task),
        onTap: () => _editTask(context, task),
      ),
    );
  }

  /// Erstellt das Layout für eine erledigte Aufgabe.
  Widget _buildCompletedTaskItem(BuildContext context, TaskModel task) {
    return Card(
      color: Colors.grey.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 1,
      child: ListTile(
        title: Text(
          task.title,
          style: const TextStyle(
            decoration: TextDecoration.lineThrough,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty) Text(task.description, overflow: TextOverflow.ellipsis),
            if (task.endDate != null)
              Text('Fällig bis: ${DateFormat('dd.MM.yyyy', 'de_DE').format(task.endDate!)}'),
            Text('Priorität: ${task.priority}'),
            Text('Dauer: ${_formatDuration(task.duration)}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.undo, color: Colors.blue),
          onPressed: () {
            context.read<TasksCubit>().restoreTask(task.id);
          },
        ),
      ),
    );
  }

  /// Erstellt das Checkbox-Element für eine aktive Aufgabe.
  Widget _buildCheckBox(BuildContext context, TaskModel task) {
    return SizedBox(
      width: 40,
      child: Transform.scale(
        scale: 0.9,
        child: Checkbox(
          value: task.isCompleted,
          onChanged: (val) {
            if (val == true) {
              context.read<TasksCubit>().markTaskAsCompleted(task.id);
            }
          },
        ),
      ),
    );
  }

  /// Stellt Informationen zur Aufgabe zusammen, z. B. Beschreibung und Fälligkeitsdatum.
  Widget _buildTaskSubInfo(TaskModel task) {
    final lines = <String>[];
    if (task.description.isNotEmpty) lines.add(task.description);
    if (task.endDate != null) {
      final formattedDate = DateFormat('dd.MM.yyyy', 'de_DE').format(task.endDate!);
      lines.add('Fällig bis: $formattedDate');
    }
    lines.add('Priorität: ${task.priority}');
    lines.add('Verbleibende Dauer: ${_formatDuration(task.duration)}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((text) => Text(text, overflow: TextOverflow.ellipsis)).toList(),
    );
  }

  /// Zeigt Bearbeiten- und Löschen-Icons an, um eine Aufgabe zu ändern oder zu entfernen.
  Widget _buildTrailingIcons(BuildContext context, TaskModel task) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () => _editTask(context, task),
          tooltip: 'Aufgabe bearbeiten',
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDelete(context, task),
          tooltip: 'Aufgabe löschen',
        ),
      ],
    );
  }

  /// Bietet eine Bestätigungs-Dialogbox an, um eine Aufgabe zu löschen.
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
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  /// Öffnet den Dialog zum Hinzufügen einer neuen Aufgabe.
  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TaskDialog(),
    );
  }

  /// Öffnet den Dialog zum Bearbeiten einer bestehenden Aufgabe.
  void _editTask(BuildContext context, TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => TaskDialog(task: task),
    );
  }

  /// Formatiert die Aufgabenlänge in Stunden und Minuten.
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}

/// Dialogfenster zum Erstellen oder Bearbeiten einer Aufgabe.
class TaskDialog extends StatefulWidget {
  final TaskModel? task;

  const TaskDialog({super.key, this.task});

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

/// Implementiert die Eingabefelder für Titel, Beschreibung, Enddatum, Priorität und Dauer.
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
      _priority = AppConstants.fixedPriorities[1];
      _durationHours = 0;
      _durationMinutes = 25;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> priorities = AppConstants.fixedPriorities;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(widget.task == null ? 'Neue Aufgabe' : 'Aufgabe bearbeiten'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTitleField(),
              const SizedBox(height: 12),
              _buildDescriptionField(),
              const SizedBox(height: 12),
              _buildEndDateField(),
              const SizedBox(height: 12),
              _buildPriorityField(priorities),
              const SizedBox(height: 12),
              _buildDurationFields(),
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

  /// Baut das Textfeld für den Titel der Aufgabe.
  Widget _buildTitleField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Titel',
        border: OutlineInputBorder(),
      ),
      initialValue: _title,
      validator: (value) => value == null || value.isEmpty ? 'Bitte einen Titel eingeben.' : null,
      onSaved: (value) => _title = value!,
    );
  }

  /// Baut das Textfeld für die Beschreibung der Aufgabe.
  Widget _buildDescriptionField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Beschreibung',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      initialValue: _description,
      onSaved: (value) => _description = value ?? '',
    );
  }

  /// Zeigt das aktuell ausgewählte Enddatum oder einen Platzhaltertext an.
  Widget _buildEndDateField() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _endDate == null
                ? 'Kein Enddatum ausgewählt'
                : 'Enddatum: ${DateFormat('dd.MM.yyyy', 'de_DE').format(_endDate!)}',
          ),
        ),
        TextButton(
          onPressed: _pickEndDate,
          child: const Text('Datum wählen'),
        ),
      ],
    );
  }

  /// Baut ein Dropdown für die Prioritätenauswahl.
  Widget _buildPriorityField(List<String> priorities) {
    return DropdownButtonFormField<String>(
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
        if (value != null) setState(() => _priority = value);
      },
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Bitte eine Priorität wählen.' : null,
    );
  }

  /// Baut die Felder für Stunden und Minuten.
  Widget _buildDurationFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Aufgabenlänge:', style: TextStyle(fontSize: 15)),
        ),
        const SizedBox(height: 5),
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
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Öffnet den DatePicker und aktualisiert das Enddatum nach Auswahl.
  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      locale: const Locale('de', 'DE'),
      context: context,
      initialDate: _endDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  /// Validiert das Formular, speichert die Eingaben und legt eine neue Aufgabe an oder aktualisiert eine bestehende.
  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      final duration = Duration(hours: _durationHours, minutes: _durationMinutes);
      if (widget.task == null) {
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
      } else {
        final updatedTask = widget.task!.copyWith(
          title: _title,
          description: _description,
          endDate: _endDate,
          priority: _priority,
          duration: duration,
        );
        context.read<TasksCubit>().updateTask(updatedTask);
      }
      Navigator.of(context).pop();
    }
  }
}
