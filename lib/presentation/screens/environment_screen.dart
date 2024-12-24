// lib/screens/environment_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/volume/volume_cubit.dart';
import '../../../logic/volume/volume_state.dart';
import '../../../logic/motion/motion_cubit.dart';
import '../../../logic/motion/motion_state.dart';
import '../../../logic/esense/esense_cubit.dart';

class EnvironmentScreen extends StatefulWidget {
  const EnvironmentScreen({super.key});

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  List<_EnvItem> checklist = [
    _EnvItem(label: 'Flasche Wasser dabei?', done: false),
    _EnvItem(label: 'Toilette gewesen?', done: false),
    _EnvItem(label: 'Handy auf lautlos?', done: false),
    _EnvItem(label: 'Schreibtisch aufgeräumt?', done: false),
  ];
  bool isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Umgebungs-Analyse'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Zeigt aktuelle Lautstärke (VolumeCubit)
            BlocBuilder<VolumeCubit, VolumeState>(
              builder: (context, state) {
                double currentDb = 0.0;
                // Unten prüfen wir, ob state VolumeNormal/TooHigh ist
                if (state is VolumeNormal) {
                  currentDb = state.decibel;
                } else if (state is VolumeTooHigh) {
                  currentDb = state.decibel;
                }
                final rating = _ratingText(currentDb);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aktuelle Lautstärke: ${currentDb.toStringAsFixed(1)} dB'),
                    Text('Status: $rating'),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),

            // eSense - Bewegung (nur wenn eSense connected)
            BlocBuilder<MotionCubit, MotionState>(
              builder: (context, state) {
                // Angenommen: eSenseConnected = (state is MotionListening)
                bool eSenseConnected = (state is MotionListening);

                if (!eSenseConnected) {
                  return const Text(
                    'Bewegungsanalyse nur mit eSense-Kopfhörer verfügbar.',
                    style: TextStyle(color: Colors.grey),
                  );
                } else {
                  // Beispiel: state MotionTooActive => "Du bewegst dich zu viel"
                  String motionStatus = 'Ruhig';
                  if (state is MotionTooActive) {
                    motionStatus = 'Zu viel Bewegung!';
                  }
                  return Text('Bewegung: $motionStatus');
                }
              },
            ),

            const SizedBox(height: 20),
            const Text(
              'Optimale Lautstärke zum Lernen: 30-50 dB\n'
              'Ok: 50-65 dB\n'
              'Schlecht: >65 dB',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isAnalyzing ? null : _startAnalysis,
              child: isAnalyzing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Umgebung analysieren (20s)'),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Checkliste für Fokus:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Alle Punkte zurücksetzen',
                  onPressed: _resetChecklist,
                ),
              ],
            ),
            _buildChecklist(),
          ],
        ),
      ),
    );
  }

  String _ratingText(double db) {
    if (db < 50) return 'Gut';
    if (db < 65) return 'Ok';
    return 'Schlecht';
  }

  /// Startet eine 20s Analyse mit dem eSense-Kopfhörer
  Future<void> _startAnalysis() async {
    // Überprüfe, ob eSense verbunden ist
    final esenseCubit = context.read<ESenseCubit>();
    final motionCubit = context.read<MotionCubit>();

    // Falls eSense nicht verbunden ist, versuche zu verbinden
    if (!(esenseCubit.state is ESenseConnected)) {
      await esenseCubit.connectToESense();
    }

    // Prüfe erneut, ob eSense verbunden ist
    if (!(esenseCubit.state is ESenseConnected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('eSense ist nicht verbunden.')),
      );
      return;
    }

    setState(() => isAnalyzing = true);

    // Simuliere eine 20s Analyse der Bewegungsdaten
    // Du kannst hier zusätzliche Logik hinzufügen, um Bewegungsdaten auszuwerten
    Timer(const Duration(seconds: 20), () {
      setState(() => isAnalyzing = false);
      _processAnalysis();
    });
  }

  void _processAnalysis() {
    // Beispielhafte Logik zur Analyse
    final motionState = context.read<MotionCubit>().state;

    String result = 'Ruhig';

    if (motionState is MotionTooActive) {
      result = 'Zu viel Bewegung!';
    }

    // Aktualisiere den VolumeCubit basierend auf der Bewegung
    // Dies ist nur ein Beispiel. Passe es entsprechend deiner Logik an.
    if (result == 'Zu viel Bewegung!') {
      context.read<VolumeCubit>().updateVolume(70.0); // Beispielwert
    } else {
      context.read<VolumeCubit>().updateVolume(40.0); // Beispielwert
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Analyse-Ergebnis'),
          content: Text('Bewegungsstatus: $result'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _resetChecklist() {
    setState(() {
      for (final item in checklist) {
        item.done = false;
      }
      checklist.sort((a, b) => a.done.toString().compareTo(b.done.toString()));
    });
  }

  Widget _buildChecklist() {
    checklist.sort((a, b) => a.done.toString().compareTo(b.done.toString()));
    return Column(
      children: checklist.map((e) {
        return CheckboxListTile(
          title: Text(
            e.label,
            style: TextStyle(
              decoration: e.done ? TextDecoration.lineThrough : null,
              color: e.done ? Colors.grey : null,
            ),
          ),
          value: e.done,
          onChanged: (val) {
            setState(() {
              e.done = val ?? false;
            });
            checklist.sort((a, b) => a.done.toString().compareTo(b.done.toString()));
          },
        );
      }).toList(),
    );
  }
}

class _EnvItem {
  String label;
  bool done;
  _EnvItem({required this.label, required this.done});
}
