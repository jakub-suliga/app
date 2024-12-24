part of 'pomodoro_cubit.dart';

abstract class PomodoroState {}

class PomodoroInitial extends PomodoroState {}

class PomodoroRunning extends PomodoroState {
  final int remainingSeconds;
  PomodoroRunning(this.remainingSeconds);
}

class PomodoroPaused extends PomodoroState {
  final int remainingSeconds;
  PomodoroPaused(this.remainingSeconds);
}

class PomodoroFinished extends PomodoroState {}
