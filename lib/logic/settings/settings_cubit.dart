import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

// Define the state
class SettingsState extends Equatable {
  final String eSenseDeviceName;
  final bool showCompletedTasks;
  final List<String> tags;
  final List<String> priorities;

  const SettingsState({
    required this.eSenseDeviceName,
    required this.showCompletedTasks,
    required this.tags,
    required this.priorities,
  });

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

  @override
  List<Object> get props => [eSenseDeviceName, showCompletedTasks, tags, priorities];
}

// Define the Cubit
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit()
      : super(const SettingsState(
          eSenseDeviceName: 'DefaultDeviceName',
          showCompletedTasks: true,
          tags: [],
          priorities: [],
        ));

  void setESenseDeviceName(String newName) {
    emit(state.copyWith(eSenseDeviceName: newName));
  }

  void toggleShowCompletedTasks(bool value) {
    emit(state.copyWith(showCompletedTasks: value));
  }

  void addTag(String tag) {
    final updatedTags = List<String>.from(state.tags)..add(tag);
    emit(state.copyWith(tags: updatedTags));
  }

  void removeTag(String tag) {
    final updatedTags = List<String>.from(state.tags)..remove(tag);
    emit(state.copyWith(tags: updatedTags));
  }

  void editTag(String oldTag, String newTag) {
    final updatedTags = state.tags.map((tag) => tag == oldTag ? newTag : tag).toList();
    emit(state.copyWith(tags: updatedTags));
  }

  void addPriority(String priority) {
    final updatedPriorities = List<String>.from(state.priorities)..add(priority);
    emit(state.copyWith(priorities: updatedPriorities));
  }

  void removePriority(String priority) {
    final updatedPriorities = List<String>.from(state.priorities)..remove(priority);
    emit(state.copyWith(priorities: updatedPriorities));
  }

  void editPriority(String oldPriority, String newPriority) {
    final updatedPriorities = state.priorities.map((prio) => prio == oldPriority ? newPriority : prio).toList();
    emit(state.copyWith(priorities: updatedPriorities));
  }

  void reorderPriorities(int oldIndex, int newIndex) {
    final updatedPriorities = List<String>.from(state.priorities);
    final item = updatedPriorities.removeAt(oldIndex);
    updatedPriorities.insert(newIndex, item);
    emit(state.copyWith(priorities: updatedPriorities));
  }
}