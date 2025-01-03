// lib/screens/pomodoro_screen.dart

import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/tasks/tasks_cubit.dart';
import '../../data/models/task_model.dart';
import '../../service/eSenseService.dart'; // Korrigierter Importpfad
import '../../logic/settings/settings_cubit.dart'; // Stelle sicher, dass SettingsCubit importiert ist

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  _PomodoroScreen createState() => _PomodoroScreen();
}

class _PomodoroScreen extends State<PomodoroScreen> {
  late PomoTimer timer;
  double _currentSessionProgress = 0.0;
  Color accent = const Color(0xFFF09E8C);
  String _selectedTaskId = '';

  // eSense-Variablen
  final ESenseService _eSenseService = ESenseService();
  String _movementStatus = 'Ruhig';
  String _buttonStatus = 'Nicht gedrückt';

  late StreamSubscription<String> _movementSub;
  late StreamSubscription<String> _buttonSub;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsCubit>().state;
    timer = PomoTimer(
      onTimerUpdate: _onTimerUpdate,
      pomodoroDuration: settings.pomodoroDuration,
      shortBreakDuration: settings.shortBreakDuration,
      longBreakDuration: settings.longBreakDuration,
      sessionsBeforeLongBreak: settings.sessionsBeforeLongBreak,
      autoStartNextPomodoro: settings.autoStartNextPomodoro,
      onSessionComplete: _handleSessionComplete,
    );

    _initializeESenseService();

    // Listener für Änderungen der Einstellungen
    context.read<SettingsCubit>().stream.listen((settings) {
      setState(() {
        timer.updateSettings(
          pomodoroDuration: settings.pomodoroDuration,
          shortBreakDuration: settings.shortBreakDuration,
          longBreakDuration: settings.longBreakDuration,
          sessionsBeforeLongBreak: settings.sessionsBeforeLongBreak,
          autoStartNextPomodoro: settings.autoStartNextPomodoro,
        );
      });
    });
  }

  @override
  void dispose() {
    timer.dispose(); // Dispose des Timers
    _movementSub.cancel();
    _buttonSub.cancel();
    _eSenseService.dispose(); // Dispose des ESenseService
    super.dispose();
  }

  // Initialisiere den eSenseService
  void _initializeESenseService() {
    final userSpecifiedName = context.read<SettingsCubit>().state.eSenseDeviceName;
    _eSenseService.initialize(userSpecifiedName);

    // Listener für Bewegungsstatus
    _movementSub = _eSenseService.movementStatusStream.listen((status) {
      setState(() {
        _movementStatus = status;
      });
    });

    // Listener für Button-Status
    _buttonSub = _eSenseService.buttonStatusStream.listen((status) {
      setState(() {
        _buttonStatus = status;
      });
    });
  }

  void _onTimerUpdate() {
    setState(() {
      _currentSessionProgress = double.parse(
        ((timer.startTime.inSeconds - timer.currentTime.inSeconds) /
                timer.startTime.inSeconds)
            .toStringAsFixed(3),
      );
    });

    // Überprüfe den Timer und handle die Pomodoro-Phasen
    if (timer.currentTime.inSeconds <= 0) {
      if (!timer.isBreak) {
        _showCompletionDialog(isSession: true);
      } else {
        _showCompletionDialog(isSession: false);
      }
    }
  }

  // Neue Methode zur Behandlung des Abschlusses einer Session oder Pause
  void _handleSessionComplete(bool isSession) {
    if (isSession) {
      // Eine Pomodoro-Session ist beendet
      timer.incrementCompletedSessions();
      if (timer.shouldTakeLongBreak()) {
        timer.startBreak(isLong: true);
      } else {
        timer.startBreak(isLong: false);
      }
    } else {
      // Eine Pause ist beendet
      if (timer.autoStartNextPomodoro) {
        timer.start();
      }
    }
  }

  void _startTimer() {
    if (_selectedTaskId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte wähle eine Aufgabe aus.')),
      );
      return;
    }
    timer.start();

    // Starte die Sensoren gleichzeitig
    if (_eSenseService.deviceStatus == 'Connected') {
      _eSenseService.startSensors();
    } else {
      debugPrint('eSense-Gerät ist nicht verbunden.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('eSense-Gerät ist nicht verbunden.')),
      );
    }
  }

  void _resetTimer() {
    timer.reset();

    // Stoppe die Sensoren gleichzeitig
    if (_eSenseService.deviceStatus == 'Connected') {
      _eSenseService.stopSensors();
    }
  }

  void _showCompletionDialog({required bool isSession}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isSession ? 'Pomodoro abgeschlossen!' : 'Pause beendet!'),
          content: Text(isSession
              ? 'Gut gemacht! Zeit für eine Pause.'
              : 'Pause beendet! Zeit für eine neue Session.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                if (isSession) {
                  // Starte automatisch die Pause
                  timer.startBreak(isLong: timer.shouldTakeLongBreak());
                  if (_eSenseService.deviceStatus == 'Connected') {
                    _eSenseService.startSensors();
                  }
                }
              },
            ),
          ],
        );
      },
    );

    // Stoppe die Sensoren nach Abschluss des Timers, falls es eine Pause ist
    if (!isSession && _eSenseService.deviceStatus == 'Connected') {
      _eSenseService.stopSensors();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Pomodoro Timer'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(5.0, 30.0, 5.0, 15.0),
          child: Column(
            children: <Widget>[
              _movementStatusDisplay(), // Bewegungsstatus anzeigen
              const SizedBox(height: 20),
              _timerWidget(),
              const SizedBox(height: 20),
              _taskDropdown(),
              const SizedBox(height: 20),
              _control(),
              const SizedBox(height: 20),
              _buttonStatusDisplay(), // Button-Status anzeigen
            ],
          ),
        ),
      );

  // Anzeige des Bewegungsstatus
  Widget _movementStatusDisplay() => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Bewegungsstatus: $_movementStatus',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );

  // Anzeige des Button-Status
  Widget _buttonStatusDisplay() => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Button: $_buttonStatus',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );

  Widget _timerWidget() => Center(
        child: SizedBox(
          width: 300.0,
          height: 350.0,
          child: Stack(
            children: <Widget>[
              _progress(type: "outer"),
              _progress(type: ''),
            ],
          ),
        ),
      );

  Widget _control() => Container(
        margin: const EdgeInsets.only(top: 50),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            elevation: 8.0,
            backgroundColor: timer.isRunning ? Colors.teal.shade200 : accent,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(30.0),
          ),
          onPressed: timer.isRunning ? _resetTimer : _startTimer,
          icon: const Icon(Icons.play_arrow),
          label: Text(
            timer.isRunning ? "RESET" : "START",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20.0,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );

  Widget _progress({required String type}) {
    final child = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: type == "outer"
            ? null
            : LinearGradient(colors: [accent, const Color(0xFFF3D4A0)]),
      ),
      child: type == "outer"
          ? RadialProgressBar(
              progressPercent: !timer.isBreak ? _currentSessionProgress : 1.0,
              progressColor: accent,
              trackColor: Colors.teal.shade50,
              trackWidth: 20.0,
              progressWidth: 20.0,
            )
          : RadialProgressBar(
              progressPercent: timer.isBreak ? _currentSessionProgress : 0.0,
              progressColor: Colors.orangeAccent,
              trackColor: Colors.teal.shade50,
              trackWidth: 20.0,
              progressWidth: 20.0,
              child: _ticker(),
            ),
    );
    return type == "outer"
        ? child
        : Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: child,
            ),
          );
  }

  Widget _ticker() => Center(
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color.fromARGB(255, 255, 255, 255),
                blurRadius: 10.0,
              ),
            ],
          ),
          child: Center(
            child: Text(
              timer.formattedCurrentTime,
              style: const TextStyle(
                fontSize: 65.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );

  Widget _taskDropdown() => BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          List<TaskModel> tasks = [];
          if (state is TasksLoaded) {
            tasks = state.tasks;
          }

          if (tasks.isEmpty) {
            return const Text('Keine Aufgaben verfügbar.');
          }

          return DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Wähle eine Aufgabe',
              border: OutlineInputBorder(),
            ),
            value: _selectedTaskId.isEmpty ? null : _selectedTaskId,
            items: tasks.map((TaskModel task) {
              return DropdownMenuItem<String>(
                value: task.id,
                child: Text(task.title),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedTaskId = newValue ?? '';
              });
            },
            validator: (value) =>
                value == null || value.isEmpty ? 'Bitte wähle eine Aufgabe aus.' : null,
          );
        },
      );
}

/// Benutzerdefinierte RadialProgressBar ohne externe Pakete
class RadialProgressBar extends StatelessWidget {
  final double progressPercent; // Wert zwischen 0.0 und 1.0
  final Color progressColor;
  final Color trackColor;
  final double trackWidth;
  final double progressWidth;
  final Widget? child; // Macht das Kind optional

  const RadialProgressBar({
    super.key,
    required this.progressPercent,
    required this.progressColor,
    required this.trackColor,
    this.trackWidth = 10.0,
    this.progressWidth = 10.0,
    this.child, // Entferne 'required'
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RadialPainter(
        progressPercent: progressPercent,
        progressColor: progressColor,
        trackColor: trackColor,
        trackWidth: trackWidth,
        progressWidth: progressWidth,
      ),
      child: child != null ? Center(child: child) : Container(), // Optionales zentriertes Kind-Widget
    );
  }
}

class RadialPainter extends CustomPainter {
  final double progressPercent;
  final Color progressColor;
  final Color trackColor;
  final double trackWidth;
  final double progressWidth;

  RadialPainter({
    required this.progressPercent,
    required this.progressColor,
    required this.trackColor,
    this.trackWidth = 10.0,
    this.progressWidth = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Mittelpunkt und Radius
    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = (size.width / 2) - max(trackWidth, progressWidth);

    // Zeichne den Track
    Paint trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = trackWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Zeichne den Fortschritt
    Paint progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = progressWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double sweepAngle = 2 * pi * progressPercent;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(RadialPainter oldDelegate) {
    return oldDelegate.progressPercent != progressPercent ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}

/// Aktualisierte PomoTimer-Klasse mit dynamischen Einstellungen
class PomoTimer {
  final Function onTimerUpdate;
  final Function(bool isSession) onSessionComplete;
  Duration pomodoroDuration;
  Duration shortBreakDuration;
  Duration longBreakDuration;
  int sessionsBeforeLongBreak;
  bool autoStartNextPomodoro;

  bool isBreak = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _internalTimer;

  Duration _currentTime;
  Duration startTime;

  int _completedSessions = 0;

  bool get isRunning => _stopwatch.isRunning;

  PomoTimer({
    required this.onTimerUpdate,
    required this.pomodoroDuration,
    required this.shortBreakDuration,
    required this.longBreakDuration,
    required this.sessionsBeforeLongBreak,
    required this.autoStartNextPomodoro,
    required this.onSessionComplete,
  })  : _currentTime = pomodoroDuration,
        startTime = pomodoroDuration;

  Duration get currentTime => _currentTime;

  String get formattedCurrentTime {
    final minutes = _currentTime.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _currentTime.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void start() {
    if (_stopwatch.isRunning) return;
    isBreak = false;
    _currentTime = pomodoroDuration;
    startTime = pomodoroDuration;
    _run();
  }

  void startBreak({required bool isLong}) {
    if (_stopwatch.isRunning) return;
    isBreak = true;
    _currentTime = isLong ? longBreakDuration : shortBreakDuration;
    startTime = _currentTime;
    _run();
  }

  void incrementCompletedSessions() {
    _completedSessions += 1;
  }

  bool shouldTakeLongBreak() {
    return _completedSessions % sessionsBeforeLongBreak == 0;
  }

  void _run() {
    _stopwatch.reset();
    _stopwatch.start();
    _timerCallback();
  }

  void _timerCallback() async {
    _currentTime = startTime - _stopwatch.elapsed;

    if (_currentTime.inSeconds > 0 && isRunning) {
      _internalTimer = Timer(const Duration(seconds: 1), _timerCallback);
    } else {
      _stopwatch.stop();
      if (!isBreak) {
        onSessionComplete(true); // Session abgeschlossen
      } else {
        onSessionComplete(false); // Pause abgeschlossen
      }
    }

    onTimerUpdate();
  }

  void reset() {
    _internalTimer?.cancel(); // Stoppe den internen Timer
    _stopwatch.stop();
    _stopwatch.reset();
    isBreak = false;
    _currentTime = pomodoroDuration;
    startTime = pomodoroDuration;
    _completedSessions = 0;
    onTimerUpdate();
  }

  void dispose() {
    _internalTimer?.cancel();
    _stopwatch.stop();
  }

  void updateSettings({
    Duration? pomodoroDuration,
    Duration? shortBreakDuration,
    Duration? longBreakDuration,
    int? sessionsBeforeLongBreak,
    bool? autoStartNextPomodoro,
  }) {
    if (pomodoroDuration != null) {
      this.pomodoroDuration = pomodoroDuration;
    }
    if (shortBreakDuration != null) {
      this.shortBreakDuration = shortBreakDuration;
    }
    if (longBreakDuration != null) {
      this.longBreakDuration = longBreakDuration;
    }
    if (sessionsBeforeLongBreak != null) {
      this.sessionsBeforeLongBreak = sessionsBeforeLongBreak;
    }
    if (autoStartNextPomodoro != null) {
      this.autoStartNextPomodoro = autoStartNextPomodoro;
    }

    // Falls der Timer gerade läuft, aktualisiere die Startzeit entsprechend
    if (isRunning) {
      if (isBreak) {
        startTime = _currentTime;
      } else {
        startTime = _currentTime;
      }
    }
  }
}
