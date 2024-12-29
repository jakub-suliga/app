import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/pomodoro/pomodoro_cubit.dart';
import '../../../logic/tasks/tasks_cubit.dart';
import '../../../data/models/task_model.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PomodoroCubit, PomodoroState>(
      builder: (context, pomodoroState) {
        // Standard: 25 min in Sekunden
        int remainingSeconds = 25 * 60;
        if (pomodoroState is PomodoroRunning) {
          remainingSeconds = pomodoroState.remainingSeconds;
        } else if (pomodoroState is PomodoroPaused) {
          remainingSeconds = pomodoroState.remainingSeconds;
        }

        final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
        final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

        final isRunning = pomodoroState is PomodoroRunning;
        final isPaused = pomodoroState is PomodoroPaused;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pomodoro'),
            centerTitle: true,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCircleIndicator(
                    pomodoroState,
                    minutes,
                    seconds,
                    isPaused,
                  ),
                  const SizedBox(height: 20),
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
  }

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
      width: 400,
      height: 400,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 10,
            backgroundColor: Colors.grey.shade300,
            // color: Colors.blue, // Optional Farbe anpassen
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$minutes:$seconds',
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
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

  /// DropdownButton für aktuelle Task-Auswahl
  Widget _buildTaskDropdown(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, tasksState) {
        if (tasksState is TasksLoaded) {
          final tasks = tasksState.tasks;
          if (tasks.isEmpty) {
            return const Text('Keine Aufgaben vorhanden.');
          }
          // Sortieren nach Fälligkeitsdatum + Prio
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
            onChanged: (newTask) {
              // Falls du was damit machen willst
              // z.B. in PomodoroCubit speichern etc.
            },
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
