// lib/presentation/screens/pomodoro_screen.dart

import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart'; // Importiere audioplayers
import '../../logic/tasks/tasks_cubit.dart';
import '../../data/models/task_model.dart';
import '../../logic/settings/settings_cubit.dart';
import '../../service/eSenseService.dart'; // Stellen Sie sicher, dass dieser Pfad korrekt ist
import '../../core/constants.dart'; // Importieren Sie die festen Prioritäten

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({Key? key}) : super(key: key);

  @override
  _PomodoroScreenState createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  late PomoTimer timer;
  double _currentSessionProgress = 0.0;
  Color accent = const Color(0xFFF09E8C);

  // eSense-Variablen
  final ESenseService _eSenseService = ESenseService();
  String _movementStatus = 'Ruhig';

  late StreamSubscription<String> _movementSub;

  TaskModel? _nextTask; // Variable für die nächste Aufgabe

  // AudioPlayer-Instanzen
  final AudioPlayer _focusPlayer = AudioPlayer();
  final AudioPlayer _movePlayer = AudioPlayer();

  // Listen der Audio-Dateien
  final List<String> _focusAudioPaths = [
    'audio/focus1.mp3',
    'audio/focus2.mp3',
    'audio/focus3.mp3',
    'audio/focus4.mp3',
  ];

  final List<String> _moveAudioPaths = [
    'audio/move1.mp3',
    'audio/move2.mp3',
    'audio/move3.mp3',
    'audio/move4.mp3',
  ];

  final Random _random = Random();

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

    // Listener für Änderungen der Aufgabenliste
    context.read<TasksCubit>().stream.listen((state) {
      if (state is TasksLoaded) {
        setState(() {
          _nextTask = context.read<TasksCubit>().getNextTask();
        });
      }
    });

    // Initiale Bestimmung der nächsten Aufgabe
    if (context.read<TasksCubit>().state is TasksLoaded) {
      _nextTask = context.read<TasksCubit>().getNextTask();
    }

    // Lade die Audio-Dateien
    _loadAudioFiles();
  }

  @override
  void dispose() {
    timer.dispose(); // Dispose des Timers
    _movementSub.cancel();
    _eSenseService.dispose(); // Dispose des ESenseService

    // Dispose der AudioPlayer-Instanzen
    _focusPlayer.dispose();
    _movePlayer.dispose();

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

      // Audio abspielen basierend auf dem Bewegungsstatus und dem aktuellen Timer-Zustand
      if (!timer.isBreak && status == 'Bewegung') {
        _playFocusAudio();
      } else if (timer.isBreak && status == 'Ruhig') {
        _playMoveAudio();
      }
    });
  }

  // Lade die Audio-Dateien (optional, da wir die Audio-Dateien bei Bedarf laden)
  void _loadAudioFiles() async {
    // Hier können wir vorab die Audio-Dateien laden, falls gewünscht
    // In diesem Beispiel laden wir sie bei Bedarf
    // Dies ist optional und kann weggelassen werden
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

  // **Modifizierte Methode zur Behandlung des Abschlusses einer Session oder Pause**
  void _handleSessionComplete(bool isSession) {
    if (isSession) {
      // Eine Pomodoro-Session ist beendet
      timer.incrementCompletedSessions();
      if (timer.shouldTakeLongBreak()) {
        timer.startBreak(isLong: true);
      } else {
        timer.startBreak(isLong: false);
      }

      // **Neue Logik zur Aktualisierung der Aufgabenzeit**
      if (_nextTask != null) {
        final tasksCubit = context.read<TasksCubit>();
        final selectedTask = _nextTask!;

        // Holen Sie sich die Pomodoro-Dauer aus den Einstellungen
        final pomodoroDuration = context.read<SettingsCubit>().state.pomodoroDuration;

        // Berechnen Sie die neue verbleibende Dauer
        final newDuration = selectedTask.duration - pomodoroDuration;

        if (newDuration <= Duration.zero) {
          // Aufgabe ist abgeschlossen und wird entfernt
          tasksCubit.removeTask(selectedTask.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Aufgabe "${selectedTask.title}" abgeschlossen und entfernt!')),
          );
        } else {
          // Aktualisieren Sie die verbleibende Dauer
          final updatedTask = selectedTask.copyWith(
            duration: newDuration,
          );
          tasksCubit.updateTask(updatedTask);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Aufgabe "${updatedTask.title}" aktualisiert: ${_formatDuration(newDuration)} verbleibend.')),
          );
        }
      }
      // **Ende der neuen Logik**

    } else {
      // Eine Pause ist beendet
      if (timer.autoStartNextPomodoro) {
        timer.start();
      }
    }

    // Aktualisiere die nächste Aufgabe nach dem Abschluss
    setState(() {
      _nextTask = context.read<TasksCubit>().getNextTask();
    });
  }

  void _startTimer() {
    if (_nextTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine bevorstehende Aufgabe verfügbar.')),
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

  /// Methode zur Anzeige der Bewegungsanweisungen
  Widget _movementInstruction() {
    if (timer.isRunning && !timer.isBreak) {
      // Während einer Pomodoro-Einheit
      if (_movementStatus == 'Bewegung') {
        return Text(
          'Bitte fokussieren Sie sich mehr und lenken Sie sich weniger ab.',
          style: TextStyle(color: Colors.red, fontSize: 16),
        );
      } else {
        return const Text(
          'Focus Time!',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        );
      }
    } else if (timer.isBreak) {
      // Während einer Pause
      if (_movementStatus == 'Ruhig') {
        return Text(
          'Bitte bewegen Sie sich mehr.',
          style: TextStyle(color: Colors.red, fontSize: 16),
        );
      } else {
        return const Text(
          'Aktiviere jetzt den Körper!',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        );
      }
    } else {
      return Container(); // Leeres Container, wenn nichts angezeigt werden soll
    }
  }

  /// Methode zur Anzeige der aktuellen Aufgabe
  Widget _currentTaskDisplay() {
    if (_nextTask == null) {
      return const Text(
        'Keine bevorstehende Aufgabe.',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );
    } else {
      return Card(
        color: Colors.blue.shade50,
        child: ListTile(
          title: Text(
            'Aktuelle Aufgabe: ${_nextTask!.title}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_nextTask!.endDate != null)
                Text('Fällig bis: ${DateFormat.yMd().format(_nextTask!.endDate!)}'),
              Text('Priorität: ${_nextTask!.priority}'),
              Text('Verbleibende Dauer: ${_formatDuration(_nextTask!.duration)}'),
            ],
          ),
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Pomodoro Timer'),
          actions: [
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () {
                Navigator.pushNamed(context, '/tasks');
              },
              tooltip: 'Aufgabenliste',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(5.0, 30.0, 5.0, 15.0),
          child: Column(
            children: <Widget>[
              _movementInstruction(), // Bewegungsanweisungen anzeigen
              const SizedBox(height: 10),
              _currentTaskDisplay(), // Anzeige der aktuellen Aufgabe
              const SizedBox(height: 20),
              _timerWidget(),
              const SizedBox(height: 20),
              _control(),
            ],
          ),
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

  /// Methode zum Abspielen der Focus-Audio-Datei zufällig ausgewählt
  void _playFocusAudio() async {
    try {
      // Wähle zufällig eine Focus-Audio-Datei aus der Liste
      final focusAudio = _focusAudioPaths[_random.nextInt(_focusAudioPaths.length)];
      await _focusPlayer.stop(); // Stoppe vorherige Wiedergaben
      await _focusPlayer.play(AssetSource(focusAudio));
    } catch (e) {
      debugPrint('Fehler beim Abspielen der Focus-Audio-Datei: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehler beim Abspielen der Fokus-Audio-Datei.')),
      );
    }
  }

  /// Methode zum Abspielen der Move-Audio-Datei zufällig ausgewählt
  void _playMoveAudio() async {
    try {
      // Wähle zufällig eine Move-Audio-Datei aus der Liste
      final moveAudio = _moveAudioPaths[_random.nextInt(_moveAudioPaths.length)];
      await _movePlayer.stop(); // Stoppe vorherige Wiedergaben
      await _movePlayer.play(AssetSource(moveAudio));
    } catch (e) {
      debugPrint('Fehler beim Abspielen der Move-Audio-Datei: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fehler beim Abspielen der Bewegungs-Audio-Datei.')),
      );
    }
  }
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
    Key? key,
    required this.progressPercent,
    required this.progressColor,
    required this.trackColor,
    this.trackWidth = 10.0,
    this.progressWidth = 10.0,
    this.child, // Entferne 'required'
  }) : super(key: key);

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

/// **Aktualisierte PomoTimer-Klasse mit dynamischen Einstellungen**
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
    final minutes = _currentTime.inMinutes.toString().padLeft(2, '0');
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
      startTime = _currentTime;
    } else {
      // **Neue Änderung: Aktualisiere _currentTime und startTime, wenn der Timer nicht läuft**
      _currentTime = pomodoroDuration ?? _currentTime;
      startTime = _currentTime;
    }

    // Benachrichtige die UI über die Aktualisierung
    onTimerUpdate();
  }
}
