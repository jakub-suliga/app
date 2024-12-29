import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'pomodoro_state.dart';

class PomodoroCubit extends Cubit<PomodoroState> {
  Timer? _timer;
  int remainingSeconds = 0;

  // Einstellbare Längen (Defaults):
  int pomodoroDuration = 25;  // in Minuten
  int shortBreak = 5;         // in Minuten
  int longBreak = 15;         // in Minuten

  PomodoroCubit() : super(PomodoroInitial());

  void setPomodoroDuration(int minutes) {
    pomodoroDuration = minutes;
  }

  void setShortBreak(int minutes) {
    shortBreak = minutes;
  }

  void setLongBreak(int minutes) {
    longBreak = minutes;
  }

  void startPomodoro() {
    remainingSeconds = pomodoroDuration * 60;
    emit(PomodoroRunning(remainingSeconds));
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        remainingSeconds--;
        emit(PomodoroRunning(remainingSeconds));
      } else {
        _timer?.cancel();
        emit(PomodoroFinished());
      }
    });
  }

  void pausePomodoro() {
    _timer?.cancel();
    emit(PomodoroPaused(remainingSeconds));
  }

  void resumePomodoro() {
    emit(PomodoroRunning(remainingSeconds));
    _startTimer();
  }

  void resetPomodoro() {
    _timer?.cancel();
    remainingSeconds = pomodoroDuration * 60;
    emit(PomodoroInitial());
  }
}
