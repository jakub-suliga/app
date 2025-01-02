import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:esense_flutter/esense.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../logic/settings/settings_cubit.dart';

class EnvironmentScreen extends StatefulWidget {
  const EnvironmentScreen({Key? key}) : super(key: key);

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

// Kleine Hilfsklasse, um magnitude + Zeitstempel zu speichern
class _AccelSample {
  final double magnitude;
  final DateTime time;
  _AccelSample(this.magnitude, this.time);
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  late ESenseManager eSenseManager;

  // eSense
  bool _connected = false;
  String _deviceStatus = 'disconnected';
  String _deviceName = 'Unknown'; // Aus eSense selbst ausgelesen
  double _voltage = -1;
  String _button = 'not pressed';
  bool _sampling = false;
  String _rawImuDataString = 'keine Daten';
  StreamSubscription? _connectionSub;
  StreamSubscription? _eSenseEventsSub;
  StreamSubscription? _sensorSub;

  // Bewegungsauswertung
  final List<_AccelSample> _accelSamples = [];
  Timer? _movementTimer;
  String _movementStatus = 'Ruhig';
  final double _threshold = 1; // Beispiel-Schwellwert
  final int _windowSeconds = 5;   // Wie viele Sekunden rückwirkend betrachtet
  final int _analysisInterval = 1; // Analyse-Intervall in Sekunden

  List<double> _accSamples = [];
  Timer? _analysisTimer;

  @override
  void initState() {
    super.initState();

    // Initialisiere den eSenseManager mit dem aktuellen Gerätenamen aus Settings
    //final userSpecifiedName =
    //    context.read<SettingsCubit>().state.eSenseDeviceName;
    final userSpecifiedName = "eSense-0629";
    eSenseManager = ESenseManager(userSpecifiedName);

    // Verbindung-Listener einrichten
    _listenToESense();

    // Bewegungsauswertung starten
    _movementTimer = Timer.periodic(
      Duration(seconds: _analysisInterval),
      (_) => _processMovement(),
    );
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    _pauseListenToSensorEvents();
    _connectionSub?.cancel();
    _eSenseEventsSub?.cancel();
    eSenseManager.disconnect();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Überwache Änderungen des Gerätenamens aus Settings
    final newDeviceName = context.read<SettingsCubit>().state.eSenseDeviceName;
    if (eSenseManager.deviceName != newDeviceName) {
      setState(() {
        eSenseManager = ESenseManager(newDeviceName);
        _connected = false;
        _deviceStatus = 'disconnected';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // eSense
  // ---------------------------------------------------------------------------

  Future<void> _askForPermissions() async {
    if (!(await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted)) {
      debugPrint(
          'WARNING - Bluetooth-Berechtigung fehlt. eSense kann nicht verbunden werden.');
    }
    if (Platform.isAndroid) {
      if (!(await Permission.locationWhenInUse.request().isGranted)) {
        debugPrint(
            'WARNING - Standort-Berechtigung fehlt. eSense kann nicht verbunden werden.');
      }
    }
  }

  Future<void> _listenToESense() async {
    await _askForPermissions();

    _connectionSub = eSenseManager.connectionEvents.listen((event) {
      debugPrint('CONNECTION event: $event');

      if (event.type == ConnectionType.connected) {
        _listenToESenseEvents();
      }

      setState(() {
        _connected = false;
        switch (event.type) {
          case ConnectionType.connected:
            _deviceStatus = 'connected';
            _connected = true;
            break;
          case ConnectionType.unknown:
            _deviceStatus = 'unknown';
            break;
          case ConnectionType.disconnected:
            _deviceStatus = 'disconnected';
            _sampling = false;
            break;
          case ConnectionType.device_found:
            _deviceStatus = 'device_found';
            break;
          case ConnectionType.device_not_found:
            _deviceStatus = 'device_not_found';
            break;
        }
      });
    });
  }

  Future<void> _connectToESense() async {
    if (!_connected) {
      debugPrint('Versuche, zu eSense zu verbinden...');
      final didConnect = await eSenseManager.connect();
      setState(() {
        _connected = didConnect;
        _deviceStatus = didConnect ? 'connecting...' : 'connection failed';
      });
    }
  }

  void _listenToESenseEvents() {
    _eSenseEventsSub = eSenseManager.eSenseEvents.listen((event) {
      debugPrint('ESENSE event: $event');

      setState(() {
        switch (event.runtimeType) {
          case DeviceNameRead:
            _deviceName = (event as DeviceNameRead).deviceName ?? 'Unknown';
            break;
          case BatteryRead:
            _voltage = (event as BatteryRead).voltage ?? -1;
            break;
          case ButtonEventChanged:
            _button = (event as ButtonEventChanged).pressed
                ? 'pressed'
                : 'not pressed';
            break;
          default:
            break;
        }
      });
    });

    _getESenseProperties();
  }

  void _getESenseProperties() {
    Timer.periodic(
      const Duration(seconds: 10),
      (timer) => _connected ? eSenseManager.getBatteryVoltage() : null,
    );

    Timer(const Duration(seconds: 2), () => eSenseManager.getDeviceName());
  }

  void _startListenToSensorEvents() {
    _sensorSub = eSenseManager.sensorEvents.listen((event) {
      final ax = event.accel?[0];
      final ay = event.accel?[1];
      final az = event.accel?[2];
      final mag = sqrt(ax! * ax + ay! * ay + az! * az).toDouble();

      _accelSamples.add(_AccelSample(mag, DateTime.now()));
      setState(() {
        _rawImuDataString =
            'Accel: [${ax.toInt()}, ${ay.toInt()}, ${az.toInt()}]';
      });
    });

    setState(() {
      _sampling = true;
    });
    _startMovementAnalysis(); // Start analyzing automatically
  }

  void _pauseListenToSensorEvents() {
    _sensorSub?.cancel();
    setState(() {
      _sampling = false;
    });
  }

  // ---------------------------------------------------------------------------
  // Bewegung in den letzten 5 Sekunden auswerten
  // ---------------------------------------------------------------------------

  void _processMovement() {
    if (!_sampling) {
      _movementStatus = 'Ruhig';
      setState(() {});
      return;
    }

    final now = DateTime.now();
    _accelSamples.removeWhere(
      (sample) => sample.time.isBefore(now.subtract(Duration(seconds: _windowSeconds))),
    );

    if (_accelSamples.isEmpty) {
      _movementStatus = 'Ruhig';
    } else {
      final sum = _accelSamples.fold<double>(0, (prev, s) => prev + s.magnitude);
      final avg = sum / _accelSamples.length;

      if (avg > _threshold) {
        _movementStatus = 'Zu viel Bewegung';
      } else {
        _movementStatus = 'Ruhig';
      }
    }

    setState(() {});
  }

  // Hilfsfunktion zur Varianzberechnung
  double _calculateVariance(List<double> data) {
    if (data.isEmpty) return 0;
    double mean = data.reduce((a, b) => a + b) / data.length;
    double sumOfSquaredDiffs =
        data.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b);
    return sumOfSquaredDiffs / data.length;
  }

  void _startMovementAnalysis() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      double variance = _calculateVariance(_accSamples);
      setState(() {
        if (variance < 0.5) {
          _movementStatus = 'Ruhig';
        } else {
          _movementStatus = 'Zu viel Bewegung';
        }
      });
      _accSamples.clear();
    });
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Environment - eSense IMU'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Verbindungsstatus: $_deviceStatus'),
          Text('Gerätename laut eSense: $_deviceName'),
          Text('Batterie: $_voltage V'),
          Text('Button: $_button'),
          const SizedBox(height: 10),
          Text('Roh-IMU-Daten: $_rawImuDataString'),
          const SizedBox(height: 10),
          Text(
            'Bewegungsstatus (letzte 5s): $_movementStatus',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _connectToESense,
            icon: const Icon(Icons.login),
            label: const Text('Verbinden'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(
                onPressed: (!_connected)
                    ? null
                    : (!_sampling)
                        ? _startListenToSensorEvents
                        : _pauseListenToSensorEvents,
                child: Text(!_sampling ? 'Sensor Start' : 'Sensor Stop'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _connected
                    ? () {
                        eSenseManager.disconnect();
                        setState(() {
                          _analysisTimer?.cancel();
                          _connected = false;
                          _deviceStatus = 'disconnected';
                        });
                      }
                    : null,
                child: const Text('Disconnect'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
