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

class TasksSettingsInitial extends TasksSettingsState {
  TasksSettingsInitial()
      : super(
          showCompletedTasks: true,
          tags: ['Wichtig', 'Dringend'],
          priorities: ['Hoch', 'Mittel', 'Niedrig'],
        );
}

class TasksSettingsUpdated extends TasksSettingsState {
  TasksSettingsUpdated({
    required super.showCompletedTasks,
    required super.tags,
    required super.priorities,
  });
}

class TasksSettingsCubit extends Cubit<TasksSettingsState> {
  TasksSettingsCubit() : super(TasksSettingsInitial());

  void toggleShowCompletedTasks(bool value) {
    emit(TasksSettingsUpdated(
      showCompletedTasks: value,
      tags: state.tags,
      priorities: state.priorities,
    ));
  }

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
