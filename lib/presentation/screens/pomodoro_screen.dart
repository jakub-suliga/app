import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Passe ggf. die Pfade zu deinen Cubits/States an
import '../../../logic/pomodoro/pomodoro_cubit.dart';
import '../../../logic/volume/volume_cubit.dart';
import '../../../logic/volume/volume_state.dart';
import '../../../logic/tasks/tasks_cubit.dart';
import '../../../data/models/task_model.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  bool _isEnvironmentTooLoud(VolumeState state) {
    // Falls du in VolumeCubit eine Pufferspeicherung von "zu laut" hast,
    // kannst du hier eine komplexere Auswertung machen.
    if (state is VolumeTooHigh) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VolumeCubit, VolumeState>(
      builder: (context, volumeState) {
        final isTooLoud = _isEnvironmentTooLoud(volumeState);

        return BlocBuilder<PomodoroCubit, PomodoroState>(
          builder: (context, pomodoroState) {
            // Restliche Zeit bestimmen
            int remainingSeconds = 0;
            if (pomodoroState is PomodoroRunning) {
              remainingSeconds = pomodoroState.remainingSeconds;
            } else if (pomodoroState is PomodoroPaused) {
              remainingSeconds = pomodoroState.remainingSeconds;
            } else {
              // PomodoroInitial oder Finished => Standard: 25 min
              remainingSeconds = 25 * 60;
            }

            final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
            final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

            // Ermitteln, ob Timer läuft / pausiert
            final isRunning = pomodoroState is PomodoroRunning;
            final isPaused = pomodoroState is PomodoroPaused;

            return Scaffold(
              // Du könntest z. B. hier auch ein dunkles Scaffold-Theme erzwingen:
              // backgroundColor: Colors.black,
              appBar: AppBar(
                title: Text(
                  isTooLoud
                      ? 'Lernumgebung: SCHLECHT'
                      : 'Lernumgebung: GUT',
                  style: TextStyle(
                    color: isTooLoud ? Colors.red : Colors.green,
                  ),
                ),
                centerTitle: true,
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // "Kreis" + Zeit
                      _buildCircleIndicator(
                        pomodoroState,
                        minutes,
                        seconds,
                        isPaused,
                      ),
                      const SizedBox(height: 20),

                      // Dropdown für aktuelle Aufgabe
                      _buildTaskDropdown(context),

                      const SizedBox(height: 20),

                      // Buttons je nach State
                      if (!isRunning && !isPaused)
                        ElevatedButton(
                          onPressed: () {
                            context.read<PomodoroCubit>().startPomodoro();
                          },
                          child: const Text('Starten'),
                        )
                      else if (isRunning)
                        ElevatedButton(
                          onPressed: () {
                            context.read<PomodoroCubit>().pausePomodoro();
                          },
                          child: const Text('Pause'),
                        )
                      else if (isPaused)
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                context.read<PomodoroCubit>().resumePomodoro();
                              },
                              child: const Text('Fortsetzen'),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                // End => reset
                                context.read<PomodoroCubit>().resetPomodoro();
                              },
                              child: const Text('Beenden'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Kreisförmiger Indikator mit großer Zeit-Anzeige
  Widget _buildCircleIndicator(
    PomodoroState state,
    String minutes,
    String seconds,
    bool isPaused,
  ) {
    const total = 25 * 60; // 25 Minuten
    double progress = 0;
    if (state is PomodoroRunning) {
      progress = 1 - (state.remainingSeconds / total);
    } else if (state is PomodoroPaused) {
      progress = 1 - (state.remainingSeconds / total);
    }

    return SizedBox(
      // Hier vergrößern wir den Kreis, damit die Zeit nicht überdeckt wird
      width: 400,
      height: 400,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dieser CircularProgressIndicator wird größer (strokeWidth, Farbe, etc.)
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 10,
            backgroundColor: Colors.grey.shade800,
            // Optional: color: ...
          ),
          // Die Zeit in der Mitte
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$minutes:$seconds',
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  // color: Colors.white, // Falls du dunklen Hintergrund willst
                ),
              ),
              if (isPaused)
                const Text(
                  'Pausiert',
                  style: TextStyle(fontSize: 18),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// DropdownButton für aktuelle Aufgabe
  Widget _buildTaskDropdown(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, tasksState) {
        if (tasksState is TasksLoaded) {
          final tasks = tasksState.tasks;
          if (tasks.isEmpty) {
            return const Text('Keine Aufgaben vorhanden.');
          }

          // Sortiere nach Fälligkeitsdatum + Prio
          final sortedTasks = [...tasks];
          sortedTasks.sort((a, b) {
            final dateA = a.dueDate ?? DateTime(3000);
            final dateB = b.dueDate ?? DateTime(3000);
            final res = dateA.compareTo(dateB);
            if (res != 0) return res;
            return b.priority.compareTo(a.priority);
          });

          // Erstes als Default
          final defaultValue = sortedTasks.first;

          return DropdownButton<TaskModel>(
            value: defaultValue,
            items: sortedTasks.map((task) {
              return DropdownMenuItem<TaskModel>(
                value: task,
                child: Text(task.title),
              );
            }).toList(),
            onChanged: (task) {
              // Hier könntest du dir die Task merken,
              // oder in TasksCubit / PomodoroCubit speichern
            },
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
