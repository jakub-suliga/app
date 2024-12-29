import 'package:flutter_bloc/flutter_bloc.dart';

/// Alle Einstellungen in einem State zusammengefasst.
class SettingsState {
  // eSense
  final String eSenseDeviceName;

  // Tasks
  final bool showCompletedTasks;
  final List<String> tags;
  final List<String> priorities;

  SettingsState({
    required this.eSenseDeviceName,
    required this.showCompletedTasks,
    required this.tags,
    required this.priorities,
  });

  // copyWith, um einzelne Felder zu überschreiben
  SettingsState copyWith({
    String? eSenseDeviceName,
    bool? showCompletedTasks,
    List<String>? tags,
    List<String>? priorities,
  }) {
    return SettingsState(
      eSenseDeviceName: eSenseDeviceName ?? this.eSenseDeviceName,
      showCompletedTasks: showCompletedTasks ?? this.showCompletedTasks,
      tags: tags ?? this.tags,
      priorities: priorities ?? this.priorities,
    );
  }
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit()
      : super(
          SettingsState(
            eSenseDeviceName: 'eSense-0332', // Default
            showCompletedTasks: true,
            tags: ['Wichtig', 'Dringend'],
            priorities: ['Hoch', 'Mittel', 'Niedrig'],
          ),
        );

  // eSense
  void setESenseDeviceName(String name) {
    emit(state.copyWith(eSenseDeviceName: name));
  }

  // Tasks
  void toggleShowCompletedTasks(bool value) {
    emit(state.copyWith(showCompletedTasks: value));
  }

  void addTag(String tag) {
    if (!state.tags.contains(tag)) {
      final updatedTags = List<String>.from(state.tags)..add(tag);
      emit(state.copyWith(tags: updatedTags));
    }
  }

  void removeTag(String tag) {
    if (state.tags.contains(tag)) {
      final updatedTags = List<String>.from(state.tags)..remove(tag);
      emit(state.copyWith(tags: updatedTags));
    }
  }

  void editTag(String oldTag, String newTag) {
    if (state.tags.contains(oldTag) && !state.tags.contains(newTag)) {
      final updatedTags = state.tags.map((tag) {
        return tag == oldTag ? newTag : tag;
      }).toList();
      emit(state.copyWith(tags: updatedTags));
    }
  }

  void addPriority(String priority) {
    if (!state.priorities.contains(priority)) {
      final updatedPriorities = List<String>.from(state.priorities)..add(priority);
      emit(state.copyWith(priorities: updatedPriorities));
    }
  }

  void removePriority(String priority) {
    if (state.priorities.contains(priority)) {
      final updatedPriorities = List<String>.from(state.priorities)..remove(priority);
      emit(state.copyWith(priorities: updatedPriorities));
    }
  }

  void editPriority(String oldPriority, String newPriority) {
    if (state.priorities.contains(oldPriority) &&
        !state.priorities.contains(newPriority)) {
      final updatedPriorities = state.priorities.map((priority) {
        return priority == oldPriority ? newPriority : priority;
      }).toList();
      emit(state.copyWith(priorities: updatedPriorities));
    }
  }

  void reorderPriorities(int oldIndex, int newIndex) {
    final updatedPriorities = List<String>.from(state.priorities);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = updatedPriorities.removeAt(oldIndex);
    updatedPriorities.insert(newIndex, item);
    emit(state.copyWith(priorities: updatedPriorities));
  }
}
