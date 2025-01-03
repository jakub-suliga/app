// lib/services/e_sense_service.dart

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:esense_flutter/esense.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../core/app.dart'; // Importiere den navigatorKey

class ESenseService {
  // Singleton-Instanz
  static final ESenseService _instance = ESenseService._internal();
  factory ESenseService() => _instance;
  ESenseService._internal();

  ESenseManager? _eSenseManager;
  String deviceStatus = 'Disconnected';
  String deviceName = 'Unknown';
  double voltage = -1;
  String button = 'Not pressed';
  bool sampling = false;
  String rawImuDataString = 'No data';
  double currentMagnitude = 0.0;
  String movementStatus = 'Ruhig';

  final int _windowSize = 30;
  final double _movementThreshold = 200.0;
  final double _maxStdDev = 15000.0;

  final List<_AccelSample> _accelSamples = [];

  // Streams zur Kommunikation mit der UI
  final StreamController<String> _deviceStatusController = StreamController.broadcast();
  final StreamController<String> _movementStatusController = StreamController.broadcast();
  final StreamController<String> _buttonStatusController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _dataController = StreamController.broadcast();

  Stream<String> get deviceStatusStream => _deviceStatusController.stream;
  Stream<String> get movementStatusStream => _movementStatusController.stream;
  Stream<String> get buttonStatusStream => _buttonStatusController.stream;
  Stream<Map<String, dynamic>> get dataStream => _dataController.stream;

  StreamSubscription? _connectionSub;
  StreamSubscription? _eSenseEventsSub;
  StreamSubscription? _sensorSub;

  Future<void> initialize(String deviceName) async {
    _eSenseManager = ESenseManager(deviceName);
    await _askForPermissions();
    _listenToESense();
  }

  Future<void> _askForPermissions() async {
    if (!(await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted)) {
      debugPrint('WARNUNG: Bluetooth-Berechtigungen fehlen. eSense kann nicht verbunden werden.');
      _deviceStatusController.add('Bluetooth-Berechtigungen fehlen');
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(content: Text('Bluetooth-Berechtigungen fehlen.')),
      );
    }
    if (Platform.isAndroid) {
      if (!(await Permission.locationWhenInUse.request().isGranted)) {
        debugPrint('WARNUNG: Standortberechtigung fehlt. eSense kann nicht verbunden werden.');
        _deviceStatusController.add('Standortberechtigung fehlt');
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(content: Text('Standortberechtigung fehlt.')),
        );
      }
    }
  }

  Future<void> _listenToESense() async {
    if (_eSenseManager == null) return;

    _connectionSub = _eSenseManager!.connectionEvents.listen((event) {
      debugPrint('CONNECTION event: $event');

      switch (event.type) {
        case ConnectionType.connected:
          deviceStatus = 'Connected';
          sampling = false; // Sensoren werden nicht automatisch gestartet
          _deviceStatusController.add(deviceStatus);
          _subscribeToESenseEvents();
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            const SnackBar(content: Text('Erfolgreich mit dem Gerät verbunden.')),
          );
          break;
        case ConnectionType.unknown:
          deviceStatus = 'Unknown';
          _deviceStatusController.add(deviceStatus);
          break;
        case ConnectionType.disconnected:
          deviceStatus = 'Disconnected';
          sampling = false;
          movementStatus = 'Ruhig';
          currentMagnitude = 0.0;
          _accelSamples.clear();
          _deviceStatusController.add(deviceStatus);
          _movementStatusController.add(movementStatus);
          _buttonStatusController.add(button);
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            const SnackBar(content: Text('Verbindung zum Gerät getrennt.')),
          );
          break;
        case ConnectionType.device_found:
          deviceStatus = 'Device found';
          _deviceStatusController.add(deviceStatus);
          break;
        case ConnectionType.device_not_found:
          deviceStatus = 'Device not found';
          _deviceStatusController.add(deviceStatus);
          break;
      }
    });

    await _connectToESense();
  }

  Future<void> _connectToESense() async {
    if (_eSenseManager == null || deviceStatus == 'Connected') return;

    debugPrint('Versuche, zu eSense zu verbinden...');
    try {
      final didConnect = await _eSenseManager!.connect();
      if (!didConnect) {
        deviceStatus = 'Connection failed';
        _deviceStatusController.add(deviceStatus);
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(content: Text('Verbindung zum Gerät fehlgeschlagen.')),
        );
      }
    } catch (e) {
      debugPrint('Fehler beim Verbinden: $e');
      deviceStatus = 'Connection failed';
      _deviceStatusController.add(deviceStatus);
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(content: Text('Verbindung zum Gerät fehlgeschlagen.')),
      );
    }
  }

  void _subscribeToESenseEvents() {
    if (_eSenseManager == null || deviceStatus != 'Connected') return;

    try {
      _eSenseEventsSub = _eSenseManager!.eSenseEvents.listen((event) {
        debugPrint('ESENSE event: $event');

        switch (event.runtimeType) {
          case DeviceNameRead:
            deviceName = (event as DeviceNameRead).deviceName ?? 'Unknown';
            _dataController.add({'deviceName': deviceName});
            break;
          case BatteryRead:
            voltage = (event as BatteryRead).voltage ?? -1;
            _dataController.add({'voltage': voltage});
            break;
          case ButtonEventChanged:
            button = (event as ButtonEventChanged).pressed ? 'Pressed' : 'Not pressed';
            _buttonStatusController.add(button);
            break;
          default:
            break;
        }
      });
    } catch (e) {
      debugPrint('Fehler beim Abonnieren der eSenseEvents: $e');
      _deviceStatusController.add('Fehler beim Empfangen von eSense-Daten');
    }

    _getESenseProperties();
  }

  void _getESenseProperties() {
    Timer.periodic(
      const Duration(seconds: 10),
      (timer) => deviceStatus == 'Connected' ? _eSenseManager!.getBatteryVoltage() : null,
    );

    Timer(const Duration(seconds: 2), () => _eSenseManager!.getDeviceName());
  }

  // Methoden zum Starten und Stoppen der Sensor-Events
  void startSensors() {
    if (_eSenseManager == null || deviceStatus != 'Connected') {
      debugPrint('Cannot start sensors: eSense is not connected.');
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(content: Text('eSense-Gerät ist nicht verbunden.')),
      );
      return;
    }

    if (sampling) return; // Bereits gestartet

    try {
      _sensorSub = _eSenseManager!.sensorEvents.listen((event) {
        if (event.accel != null) {
          final ax = event.accel![0];
          final ay = event.accel![1];
          final az = event.accel![2];
          final mag = sqrt(ax * ax + ay * ay + az * az).toDouble();

          final now = DateTime.now();
          _accelSamples.add(_AccelSample(mag, now));

          if (_accelSamples.length > _windowSize) {
            _accelSamples.removeAt(0);
          }

          rawImuDataString =
              'Accel: [${ax.toStringAsFixed(2)}, ${ay.toStringAsFixed(2)}, ${az.toStringAsFixed(2)}]';
          currentMagnitude = mag;

          _dataController.add({
            'rawImuData': rawImuDataString,
            'currentMagnitude': currentMagnitude,
          });

          debugPrint('IMU-Daten empfangen: ax=$ax, ay=$ay, az=$az, mag=$mag');

          if (_accelSamples.length == _windowSize) {
            final magnitudes = _accelSamples.map((s) => s.magnitude).toList();
            final stdDev = _calculateStandardDeviation(magnitudes);

            debugPrint('Standardabweichung: $stdDev');

            if (stdDev > _movementThreshold && stdDev < _maxStdDev) {
              debugPrint('Bewegung erkannt.');
              _updateMovementStatus('Man bewegt sich');
            } else if (stdDev <= _movementThreshold) {
              debugPrint('Keine Bewegung erkannt.');
              _updateMovementStatus('Ruhig');
            }
          }
        }
      });

      sampling = true;
      _deviceStatusController.add('Sensor-Events abonniert');
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(content: Text('Sensor-Events abonniert.')),
      );
    } catch (e) {
      debugPrint('Fehler beim Abonnieren der Sensor-Events: $e');
      _deviceStatusController.add('Fehler beim Abonnieren der Sensor-Events');
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(content: Text('Fehler beim Abonnieren der Sensor-Events.')),
      );
    }
  }

  void stopSensors() {
    _sensorSub?.cancel();
    _sensorSub = null;
    sampling = false;
    _accelSamples.clear();
    movementStatus = 'Ruhig';
    currentMagnitude = 0.0;
    rawImuDataString = 'No data';
    _deviceStatusController.add('Sensor-Events abbestellt');
    _movementStatusController.add(movementStatus);
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      const SnackBar(content: Text('Sensor-Events abbestellt.')),
    );
  }

  void _updateMovementStatus(String status) {
    if (movementStatus != status) {
      movementStatus = status;
      _movementStatusController.add(movementStatus);
    }
  }

  double _calculateStandardDeviation(List<double> data) {
    if (data.isEmpty) return 0.0;
    double mean = data.reduce((a, b) => a + b) / data.length;
    num sumOfSquaredDiffs =
        data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b);
    return sqrt(sumOfSquaredDiffs / data.length);
  }

  Future<void> disconnect() async {
    stopSensors(); // Stelle sicher, dass Sensoren gestoppt werden
    await _eSenseManager?.disconnect();
    deviceStatus = 'Disconnected';
    sampling = false;
    movementStatus = 'Ruhig';
    currentMagnitude = 0.0;
    _accelSamples.clear();
    _deviceStatusController.add(deviceStatus);
    _movementStatusController.add(movementStatus);
    _buttonStatusController.add(button);
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      const SnackBar(content: Text('Erfolgreich getrennt.')),
    );
  }

  /// **Wichtig: Definiere die dispose-Methode korrekt**
  void dispose() {
    _sensorSub?.cancel();
    _eSenseEventsSub?.cancel();
    _connectionSub?.cancel();
    _deviceStatusController.close();
    _movementStatusController.close();
    _buttonStatusController.close();
    _dataController.close();
  }
}

// Hilfsklasse zum Speichern der Magnitude und des Zeitstempels
class _AccelSample {
  final double magnitude;
  final DateTime time;
  _AccelSample(this.magnitude, this.time);
}