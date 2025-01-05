import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../logic/tasks/tasks_cubit.dart';
import '../../../data/models/task_model.dart';
import '../../../logic/settings/settings_cubit.dart';
import '../../../service/eSenseService.dart';
import '../../../logic/history/history_cubit.dart';
import '../../../data/models/history_entry_model.dart';

/// Stellt den Pomodoro-Screen bereit, inklusive eSense-Anbindung und Aufgaben-Logik.
class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  _PomodoroScreenState createState() => _PomodoroScreenState();
}

/// Steuert den Timer, Aufgabenwechsel und Audio-Feedback.
class _PomodoroScreenState extends State<PomodoroScreen> {
  late PomoTimer timer;
  double _currentSessionProgress = 0.0;
  final ESenseService _eSenseService = ESenseService();
  String _movementStatus = 'Ruhig';
  late StreamSubscription<String> _movementSub;
  TaskModel? _nextTask;
  final AudioPlayer _focusPlayer = AudioPlayer();
  final AudioPlayer _movePlayer = AudioPlayer();
  final AudioPlayer _alarmPlayer = AudioPlayer();

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

  final String _alarmAudioPath = 'audio/alarm.mp3';
  final Random _random = Random();
  DateTime _currentWeekStart = _findFirstDayOfWeek(DateTime.now());

  /// Findet den Montag der aktuellen Woche.
  static DateTime _findFirstDayOfWeek(DateTime date) {
    int subtractDays = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: subtractDays));
  }

  /// Zeigt die vorherige Woche an.
  void _goToPreviousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  /// Zeigt die nächste Woche an.
  void _goToNextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }

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
    context.read<TasksCubit>().stream.listen((state) {
      if (state is TasksLoaded) {
        setState(() {
          _nextTask = context.read<TasksCubit>().getNextTask();
        });
      }
    });
    if (context.read<TasksCubit>().state is TasksLoaded) {
      _nextTask = context.read<TasksCubit>().getNextTask();
    }
  }

  @override
  void dispose() {
    timer.dispose();
    _movementSub.cancel();
    _eSenseService.dispose();
    _focusPlayer.dispose();
    _movePlayer.dispose();
    _alarmPlayer.dispose();
    super.dispose();
  }

  /// Initialisiert eSense und startet den Bewegungssensor.
  void _initializeESenseService() {
    final userSpecifiedName = context.read<SettingsCubit>().state.eSenseDeviceName;
    _eSenseService.initialize(userSpecifiedName);
    _movementSub = _eSenseService.movementStatusStream.listen((status) {
      setState(() {
        _movementStatus = status;
      });
      if (!timer.isBreak && status == 'Bewegung') {
        _playFocusAudio();
      } else if (timer.isBreak && status == 'Ruhig') {
        _playMoveAudio();
      }
    });
  }

  /// Aktualisiert den Fortschritt und prüft, ob die Session abgeschlossen ist.
  void _onTimerUpdate() {
    setState(() {
      _currentSessionProgress = double.parse(
        ((timer.startTime.inSeconds - timer.currentTime.inSeconds) / timer.startTime.inSeconds)
            .toStringAsFixed(3),
      );
    });
    if (timer.currentTime.inSeconds <= 0) {
      if (!timer.isBreak) {
        _showCompletionDialog(isSession: true);
      } else {
        _showCompletionDialog(isSession: false);
      }
    }
  }

  /// Verarbeitet das Ende einer Pomodoro-Session oder Pause.
  void _handleSessionComplete(bool isSession) {
    if (isSession) {
      timer.incrementCompletedSessions();
      if (timer.shouldTakeLongBreak()) {
        timer.startBreak(isLong: true);
      } else {
        timer.startBreak(isLong: false);
      }
      if (_nextTask != null) {
        final tasksCubit = context.read<TasksCubit>();
        final selectedTask = _nextTask!;
        final pomodoroDuration = context.read<SettingsCubit>().state.pomodoroDuration;
        final newDuration = selectedTask.duration - pomodoroDuration;
        if (newDuration <= Duration.zero) {
          tasksCubit.markTaskAsCompleted(selectedTask.id);
        } else {
          final updatedTask = selectedTask.copyWith(duration: newDuration);
          tasksCubit.updateTask(updatedTask);
        }
        final historyCubit = context.read<HistoryCubit>();
        final today = DateTime.now();
        final pomodoroDetail = PomodoroDetail(
          duration: pomodoroDuration,
          taskTitle: selectedTask.title,
        );
        historyCubit.addPomodoro(today, pomodoroDetail).then((_) {}).catchError((error) {});
      }
      _playAlarm();
    } else {
      if (timer.autoStartNextPomodoro) {
        timer.start();
      }
    }
    setState(() {
      _nextTask = context.read<TasksCubit>().getNextTask();
    });
  }

  /// Startet eine Pomodoro-Session.
  void _startTimer() {
    timer.start();
    if (_eSenseService.deviceStatus == 'Connected') {
      _eSenseService.startSensors();
    }
  }

  /// Setzt den Timer zurück und stoppt ggf. die Sensoren.
  void _resetTimer() {
    timer.reset();
    if (_eSenseService.deviceStatus == 'Connected') {
      _eSenseService.stopSensors();
    }
  }

  /// Zeigt einen Dialog nach Ende einer Session oder Pause.
  void _showCompletionDialog({required bool isSession}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isSession ? 'Pomodoro abgeschlossen!' : 'Pause beendet!'),
          content: Text(isSession ? 'Gut gemacht! Zeit für eine Pause.' : 'Pause beendet! Weiter geht’s.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                if (isSession) {
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
    if (!isSession && _eSenseService.deviceStatus == 'Connected') {
      _eSenseService.stopSensors();
    }
  }

  /// Wandelt ein Duration-Objekt in eine Stunden/Minuten-Stringausgabe um.
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  /// Gibt an, welche Aufgabe aktuell aktiv ist, oder fordert zum Anlegen einer auf.
  Widget _currentTaskDisplay() {
    if (_nextTask == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
        child: ListTile(
          leading: const Icon(Icons.assignment, color: Colors.black54),
          title: const Text('Aktuelle Aufgabe', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Keine Aufgaben. Füge eine Aufgabe hinzu!', style: TextStyle(fontSize: 16)),
        ),
      );
    } else {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
        child: ListTile(
          leading: const Icon(Icons.assignment_outlined, color: Colors.black54),
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

  /// Zeigt den aktuellen Fokus- bzw. Bewegungsstatus.
  Widget _focusStatusDisplay() {
    String focusStatus = '';
    if (timer.isRunning && !timer.isBreak) {
      if (_movementStatus == 'Ruhig') {
        focusStatus = 'Fokussiert';
      } else if (_movementStatus == 'Bewegung') {
        focusStatus = 'Abgelenkt';
      }
    } else if (timer.isBreak) {
      if (_movementStatus == 'Bewegung') {
        focusStatus = 'Gute Bewegung!';
      } else if (_movementStatus == 'Ruhig') {
        focusStatus = 'Mehr bewegen!';
      }
    } else {
      focusStatus = 'Starte eine Pomodoro Einheit!';
    }
    IconData statusIcon;
    Color iconColor;
    switch (focusStatus) {
      case 'Fokussiert':
        statusIcon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'Abgelenkt':
        statusIcon = Icons.warning;
        iconColor = Colors.red;
        break;
      case 'Gute Bewegung!':
        statusIcon = Icons.directions_walk;
        iconColor = Colors.green;
        break;
      case 'Mehr bewegen!':
        statusIcon = Icons.directions_run;
        iconColor = Colors.orange;
        break;
      default:
        statusIcon = Icons.play_circle_fill;
        iconColor = Colors.blue;
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: ListTile(
        leading: Icon(statusIcon, color: iconColor, size: 30),
        title: const Text('Fokus Status', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(focusStatus, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  /// Zeigt eine Wochenübersicht mit Streak-Anzeige.
  Widget _weeklyProgressWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('Tägliche Aufgaben Challenge', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
            child: BlocBuilder<HistoryCubit, HistoryState>(
              builder: (context, state) {
                if (state is! HistoryLoaded) {
                  return const SizedBox.shrink();
                }
                final history = state.history;
                List<DateTime> weekDays = List.generate(7, (index) {
                  return _currentWeekStart.add(Duration(days: index));
                });
                List<bool> tasksCompleted = weekDays.map((day) {
                  return history.any(
                    (entry) => _isSameDay(entry.date, day) && entry.pomodoroCount > 0,
                  );
                }).toList();
                final streakCount = _calculateStreak(history);
                return Column(
                  children: [
                    _buildStreakWidget(streakCount),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(icon: const Icon(Icons.arrow_left), onPressed: _goToPreviousWeek),
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(7, (index) {
                                final day = weekDays[index];
                                final isCompleted = tasksCompleted[index];
                                final dayLabel = DateFormat.E().format(day);
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 6.0),
                                  child: Column(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 500),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isCompleted ? Colors.green : Colors.grey,
                                            width: 2.0,
                                          ),
                                          boxShadow: isCompleted
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.green.withOpacity(0.5),
                                                    spreadRadius: 2,
                                                    blurRadius: 5,
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.white,
                                          child: Text(
                                            dayLabel.substring(0, 2),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(DateFormat.d().format(day), style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.arrow_right), onPressed: _goToNextWeek),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Zeigt die Streak-Information in einer Zeile an.
  Widget _buildStreakWidget(int streakCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.local_fire_department, color: Colors.orange),
        const SizedBox(width: 8),
        Text(
          streakCount > 1
              ? 'Streak: $streakCount Tage in Folge geschafft!'
              : (streakCount == 1 ? 'Streak: 1 Tag in Folge geschafft!' : 'Aktuell kein Streak vorhanden.'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Ermittelt, wie viele Tage hintereinander ein Pomodoro absolviert wurde.
  int _calculateStreak(List<HistoryEntryModel> history) {
    int streak = 0;
    DateTime today = DateTime.now();
    final nowDateOnly = DateTime(today.year, today.month, today.day);
    DateTime dayCheck = nowDateOnly;
    while (true) {
      final found = history.any((entry) => _isSameDay(entry.date, dayCheck) && entry.pomodoroCount > 0);
      if (found) {
        streak++;
        dayCheck = dayCheck.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// Prüft, ob zwei Datumsobjekte denselben Kalendertag repräsentieren.
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12.0, 20.0, 12.0, 15.0),
        child: Column(
          children: [
            _focusStatusDisplay(),
            const SizedBox(height: 10),
            _currentTaskDisplay(),
            const SizedBox(height: 24),
            _timerWidget(),
            const SizedBox(height: 20),
            _control(),
            const SizedBox(height: 24),
            _weeklyProgressWidget(),
          ],
        ),
      ),
    );
  }

  /// Baut das Layout für den Timer mit äußerem und innerem Kreis.
  Widget _timerWidget() => Center(
        child: SizedBox(
          width: 300.0,
          height: 350.0,
          child: Stack(
            children: [
              _progress(type: "outer"),
              _progress(type: ''),
            ],
          ),
        ),
      );

  /// Zeigt den Start/Reset-Button.
  Widget _control() => Container(
        margin: const EdgeInsets.only(top: 16),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            elevation: 2.0,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(28.0),
          ),
          onPressed: timer.isRunning ? _resetTimer : _startTimer,
          icon: Icon(timer.isRunning ? Icons.stop : Icons.play_arrow),
          label: Text(
            timer.isRunning ? "RESET" : "START",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
          ),
        ),
      );

  /// Erstellt den äußeren (Session) und inneren (Pause) Fortschrittskreis.
  Widget _progress({required String type}) {
    final child = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: type == "outer"
            ? null
            : const LinearGradient(
                colors: [Colors.white, Color(0xFFFAFAFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: type == "outer"
          ? RadialProgressBar(
              progressPercent: !timer.isBreak ? _currentSessionProgress : 1.0,
              progressColor: Colors.blueAccent,
              trackColor: Colors.grey.shade300,
              trackWidth: 20.0,
              progressWidth: 20.0,
            )
          : RadialProgressBar(
              progressPercent: timer.isBreak ? _currentSessionProgress : 0.0,
              progressColor: Colors.blueAccent,
              trackColor: Colors.grey.shade300,
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

  /// Zeigt die ablaufende Zeit innerhalb des inneren Kreises.
  Widget _ticker() => Center(
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.white, blurRadius: 6.0)],
          ),
          child: Center(
            child: Text(
              timer.formattedCurrentTime,
              style: const TextStyle(fontSize: 60.0, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );

  /// Spielt ein zufälliges Fokus-Audio ab.
  void _playFocusAudio() async {
    try {
      final focusAudio = _focusAudioPaths[_random.nextInt(_focusAudioPaths.length)];
      await _focusPlayer.stop();
      await _focusPlayer.play(AssetSource(focusAudio));
    } catch (e) {}
  }

  /// Spielt ein zufälliges Bewegungs-Audio ab.
  void _playMoveAudio() async {
    try {
      final moveAudio = _moveAudioPaths[_random.nextInt(_moveAudioPaths.length)];
      await _movePlayer.stop();
      await _movePlayer.play(AssetSource(moveAudio));
    } catch (e) {}
  }

  /// Spielt einen Alarmton am Ende einer Session.
  void _playAlarm() async {
    try {
      await _alarmPlayer.stop();
      await _alarmPlayer.play(AssetSource(_alarmAudioPath));
    } catch (e) {}
  }
}

/// Zeichnet einen kreisförmigen Fortschrittsbalken für Session- oder Pausenzeit.
class RadialProgressBar extends StatelessWidget {
  final double progressPercent;
  final Color progressColor;
  final Color trackColor;
  final double trackWidth;
  final double progressWidth;
  final Widget? child;

  const RadialProgressBar({
    super.key,
    required this.progressPercent,
    required this.progressColor,
    required this.trackColor,
    this.trackWidth = 10.0,
    this.progressWidth = 10.0,
    this.child,
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
      child: child != null ? Center(child: child) : Container(),
    );
  }
}

/// Beschreibt, wie der Fortschritt gekrümmt gezeichnet wird.
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
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - max(trackWidth, progressWidth);
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = trackWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = progressWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final sweepAngle = 2 * pi * progressPercent;
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

/// Kapselt die Pomodoro-Zeitabläufe und Sessions/Pausen-Übergänge.
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
        onSessionComplete(true);
      } else {
        onSessionComplete(false);
      }
    }
    onTimerUpdate();
  }

  void reset() {
    _internalTimer?.cancel();
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
    if (isRunning) {
      startTime = _currentTime;
    } else {
      _currentTime = pomodoroDuration ?? _currentTime;
      startTime = _currentTime;
    }
    onTimerUpdate();
  }
}
