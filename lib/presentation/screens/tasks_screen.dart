// lib/screens/tasks_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/tasks/tasks_cubit.dart';
import '../../../data/models/task_model.dart';

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
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return ListTile(
                      leading: Checkbox(
                        value: task.isDone ?? false,
                        onChanged: (val) {
                          // Abgehakt => Cubit: updateTask
                          final updatedTask = task.copyWith(isDone: val ?? false);
                          context.read<TasksCubit>().updateTask(updatedTask);
                        },
                      ),
                      title: GestureDetector(
                        onTap: () => _editTask(task),
                        child: Text(task.title),
                      ),
                      subtitle: Text(_taskSubtitle(task)),
                    );
                  },
                ),
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
      tasks = tasks.where((t) => _prioName(t.priority) == selectedPrio).toList();
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

  String _taskSubtitle(TaskModel task) {
    // Anzeige von Deadline und Priorität
    final prioText = _prioName(task.priority);
    // final tagText = task.tags.isEmpty ? '' : '#${task.tags.join(' #')}'; // Entfernt
    final due = task.dueDate != null ? 'Fällig: ${task.dueDate}' : '';
    return '$due | Prio: $prioText';
  }

  String _prioName(int priority) {
    switch (priority) {
      case 2:
        return 'Hoch';
      case 0:
        return 'Niedrig';
      default:
        return 'Mittel';
    }
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
              DropdownMenuItem(value: 'Mittel', child: Text('Mittel')),
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
    // BottomSheet oder Popup
    showModalBottomSheet(
      context: context,
      builder: (ctx) => const _TaskCreationSheet(),
    );
  }

  void _editTask(TaskModel task) {
    // Implementieren Sie das Bearbeiten einer Aufgabe hier, falls gewünscht
  }
}

// Ein vereinfachtes BottomSheet:
class _TaskCreationSheet extends StatefulWidget {
  const _TaskCreationSheet();

  @override
  State<_TaskCreationSheet> createState() => _TaskCreationSheetState();
}

class _TaskCreationSheetState extends State<_TaskCreationSheet> {
  String title = '';
  String description = '';
  // List<String> tags = []; // Entfernt
  int priority = 1; // 0=niedrig,1=mittel,2=hoch
  bool repeatDaily = false;
  // etc.

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Title
            TextField(
              decoration: const InputDecoration(hintText: 'Titel'),
              onChanged: (val) {
                setState(() {
                  title = val;
                  // Bei #... => tag extrahieren
                });
              },
            ),
            // Icons: [Wiederholen], [Prio], [Tags], [Liste]
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.repeat),
                  onPressed: () {
                    setState(() {
                      repeatDaily = !repeatDaily;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.priority_high),
                  onPressed: _choosePrio,
                ),
                // Entfernen der Tag- und Listen-Buttons
                /*
                IconButton(
                  icon: const Icon(Icons.tag),
                  onPressed: _chooseTag,
                ),
                IconButton(
                  icon: const Icon(Icons.list_alt),
                  onPressed: _chooseList,
                ),
                */
              ],
            ),
            TextField(
              decoration: const InputDecoration(hintText: 'Beschreibung'),
              onChanged: (val) => description = val,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: title.isEmpty ? null : _saveTask,
              child: const Text('Speichern'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _choosePrio() async {
    // Beispiel: Einfache Dialog
    final newPrio = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Priorität'),
          children: [
            SimpleDialogOption(
              child: const Text('Hoch'),
              onPressed: () => Navigator.pop(ctx, 2),
            ),
            SimpleDialogOption(
              child: const Text('Mittel'),
              onPressed: () => Navigator.pop(ctx, 1),
            ),
            SimpleDialogOption(
              child: const Text('Niedrig'),
              onPressed: () => Navigator.pop(ctx, 0),
            ),
          ],
        );
      },
    );
    if (newPrio != null) {
      setState(() {
        priority = newPrio;
      });
    }
  }

  // Entfernen der Methoden _chooseTag und _chooseList

  void _saveTask() {
    final newTask = TaskModel(
      id: DateTime.now().toString(),
      title: title,
      description: description,
      // parse tags from title or special logic
      // tags: tags, // Entfernt
      priority: priority,
      repeatDaily: repeatDaily,
      // ...
    );
    context.read<TasksCubit>().addTask(newTask);
    Navigator.pop(context);
  }
}
