// lib/logic/tasks/tasks_settings_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

/// Definiert die verschiedenen Zustände für die Aufgabenlisten-Einstellungen.
abstract class TasksSettingsState {
  final bool showCompletedTasks;
  final List<String> tags;
  final List<String> priorities;

  TasksSettingsState({
    required this.showCompletedTasks,
    required this.tags,
    required this.priorities,
  });
}

/// Initialzustand mit Standardwerten.
class TasksSettingsInitial extends TasksSettingsState {
  TasksSettingsInitial()
      : super(
          showCompletedTasks: true,
          tags: ['Wichtig', 'Dringend'],
          priorities: ['Hoch', 'Mittel', 'Niedrig'],
        );
}

/// Zustand nach einer Aktualisierung der Einstellungen.
class TasksSettingsUpdated extends TasksSettingsState {
  TasksSettingsUpdated({
    required super.showCompletedTasks,
    required super.tags,
    required super.priorities,
  });
}

/// Cubit zur Verwaltung der Aufgabenlisten-Einstellungen.
class TasksSettingsCubit extends Cubit<TasksSettingsState> {
  TasksSettingsCubit() : super(TasksSettingsInitial());

  /// Umschalten der Sichtbarkeit erledigter Aufgaben.
  void toggleShowCompletedTasks(bool value) {
    emit(TasksSettingsUpdated(
      showCompletedTasks: value,
      tags: state.tags,
      priorities: state.priorities,
    ));
  }

  /// Hinzufügen eines neuen Tags.
  void addTag(String tag) {
    if (!state.tags.contains(tag)) {
      final updatedTags = List<String>.from(state.tags)..add(tag);
      emit(TasksSettingsUpdated(
        showCompletedTasks: state.showCompletedTasks,
        tags: updatedTags,
        priorities: state.priorities,
      ));
    }
  }

  /// Entfernen eines Tags.
  void removeTag(String tag) {
    if (state.tags.contains(tag)) {
      final updatedTags = List<String>.from(state.tags)..remove(tag);
      emit(TasksSettingsUpdated(
        showCompletedTasks: state.showCompletedTasks,
        tags: updatedTags,
        priorities: state.priorities,
      ));
    }
  }

  /// Bearbeiten eines Tags.
  void editTag(String oldTag, String newTag) {
    if (state.tags.contains(oldTag) && !state.tags.contains(newTag)) {
      final updatedTags = state.tags.map((tag) {
        return tag == oldTag ? newTag : tag;
      }).toList();
      emit(TasksSettingsUpdated(
        showCompletedTasks: state.showCompletedTasks,
        tags: updatedTags,
        priorities: state.priorities,
      ));
    }
  }

  /// Hinzufügen einer neuen Priorität.
  void addPriority(String priority) {
    if (!state.priorities.contains(priority)) {
      final updatedPriorities = List<String>.from(state.priorities)..add(priority);
      emit(TasksSettingsUpdated(
        showCompletedTasks: state.showCompletedTasks,
        tags: state.tags,
        priorities: updatedPriorities,
      ));
    }
  }

  /// Entfernen einer Priorität.
  void removePriority(String priority) {
    if (state.priorities.contains(priority)) {
      final updatedPriorities = List<String>.from(state.priorities)..remove(priority);
      emit(TasksSettingsUpdated(
        showCompletedTasks: state.showCompletedTasks,
        tags: state.tags,
        priorities: updatedPriorities,
      ));
    }
  }

  /// Bearbeiten einer Priorität.
  void editPriority(String oldPriority, String newPriority) {
    if (state.priorities.contains(oldPriority) && !state.priorities.contains(newPriority)) {
      final updatedPriorities = state.priorities.map((priority) {
        return priority == oldPriority ? newPriority : priority;
      }).toList();
      emit(TasksSettingsUpdated(
        showCompletedTasks: state.showCompletedTasks,
        tags: state.tags,
        priorities: updatedPriorities,
      ));
    }
  }

  /// Ändern der Reihenfolge der Prioritäten.
  void reorderPriorities(int oldIndex, int newIndex) {
    final updatedPriorities = List<String>.from(state.priorities);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = updatedPriorities.removeAt(oldIndex);
    updatedPriorities.insert(newIndex, item);
    emit(TasksSettingsUpdated(
      showCompletedTasks: state.showCompletedTasks,
      tags: state.tags,
      priorities: updatedPriorities,
    ));
  }
}
