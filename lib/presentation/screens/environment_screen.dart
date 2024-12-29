import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/esense/esense_cubit.dart';
import '../../../logic/motion/motion_cubit.dart';
import '../../../logic/motion/motion_state.dart';
import '../../../logic/volume/volume_cubit.dart';
import '../../../logic/volume/volume_state.dart';

class EnvironmentScreen extends StatefulWidget {
  const EnvironmentScreen({super.key});

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  bool isAnalyzing = false;
  final List<double> _collectedDbValues = [];
  Timer? _analysisTimer;
  StreamSubscription<VolumeState>? _volumeSub;
  StreamSubscription<MotionState>? _motionSub;
  bool _tooLoud = false;
  bool _tooActive = false;

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _volumeSub?.cancel();
    _motionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esenseState = context.watch<ESenseCubit>().state;
    final isESenseConnected = esenseState is ESenseConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lernanalyse'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!isESenseConnected) ...[
              const Text(
                'Du benötigst eSense-Kopfhörer für die Lernanalyse!',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _tryConnectESense,
                child: const Text('eSense verbinden'),
              ),
            ] else ...[
              const Text(
                'eSense ist verbunden – du kannst jetzt eine Analyse starten.',
                style: TextStyle(fontSize: 16),
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
                    : const Text('Starte 10-Sekunden-Analyse'),
              ),
              const SizedBox(height: 20),
              if (_tooLoud)
                const Text(
                  'Achtung, es ist zu laut!',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              if (_tooActive)
                const Text(
                  'Bitte nicht so viel bewegen!',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              if (!_tooLoud && !_tooActive && !isAnalyzing && isESenseConnected)
                const Text(
                  'Umgebung sieht gut aus!',
                  style: TextStyle(color: Colors.green),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _tryConnectESense() async {
    context.read<ESenseCubit>().connectToESense();
  }

  Future<void> _startAnalysis() async {
    setState(() {
      isAnalyzing = true;
      _tooLoud = false;
      _tooActive = false;
      _collectedDbValues.clear();
    });

    final volumeCubit = context.read<VolumeCubit>();
    final motionCubit = context.read<MotionCubit>();

    motionCubit.startMonitoring();
    _motionSub = motionCubit.stream.listen((mState) {
      if (mState is MotionTooActive) _tooActive = true;
    });

    _volumeSub = volumeCubit.stream.listen((state) {
      if (state is VolumeNormal || state is VolumeTooHigh) {
        _collectedDbValues.add(state.decibel);
      }
    });

    _analysisTimer = Timer(const Duration(seconds: 10), _finishAnalysis);
  }

  void _finishAnalysis() {
    if (_collectedDbValues.isNotEmpty) {
      final avgDb = _collectedDbValues.reduce((a, b) => a + b) / _collectedDbValues.length;
      if (avgDb > 60.0) {
        _tooLoud = true;
      }
    }

    _analysisTimer?.cancel();
    _analysisTimer = null;
    _volumeSub?.cancel();
    _volumeSub = null;
    _motionSub?.cancel();
    _motionSub = null;

    context.read<MotionCubit>().stopMonitoring();
    setState(() => isAnalyzing = false);
  }
}
