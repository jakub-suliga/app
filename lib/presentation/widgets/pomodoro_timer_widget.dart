import 'package:flutter/material.dart';
import '../../logic/pomodoro/pomodoro_cubit.dart';

class PomodoroTimerWidget extends StatelessWidget {
  final PomodoroState pomodoroState;
  const PomodoroTimerWidget({super.key, required this.pomodoroState});

  @override
  Widget build(BuildContext context) {
    int remainingSeconds = 0;
    if (pomodoroState is PomodoroRunning) {
      remainingSeconds = (pomodoroState as PomodoroRunning).remainingSeconds;
    } else if (pomodoroState is PomodoroPaused) {
      remainingSeconds = (pomodoroState as PomodoroPaused).remainingSeconds;
    }

    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

    return Text(
      '$minutes:$seconds',
      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
    );
  }
}
