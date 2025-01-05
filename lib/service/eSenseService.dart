import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:esense_flutter/esense.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service zur Verwaltung der Verbindung und Sensor-Daten eines eSense-Geräts.
/// Verwendet ein Singleton-Muster, damit nur eine Instanz existiert.
class ESenseService {
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

  /// Initialisiert den Manager mit dem gegebenen Namen und fragt Berechtigungen an.
  Future<void> initialize(String deviceName) async {
    _eSenseManager = ESenseManager(deviceName);
    await _askForPermissions();
    await _listenToESense();
  }

  /// Fragt Bluetooth- und ggf. Standortberechtigungen an.
  Future<void> _askForPermissions() async {
    if (!(await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted)) {
      _deviceStatusController.add('Bluetooth-Berechtigungen fehlen');
    }
    if (Platform.isAndroid) {
      if (!(await Permission.locationWhenInUse.request().isGranted)) {
        _deviceStatusController.add('Standortberechtigung fehlt');
      }
    }
  }

  /// Lauscht auf Verbindungsevents und versucht, eine Verbindung herzustellen.
  Future<void> _listenToESense() async {
    if (_eSenseManager == null) return;

    _connectionSub = _eSenseManager!.connectionEvents.listen((event) {
      switch (event.type) {
        case ConnectionType.connected:
          deviceStatus = 'Connected';
          sampling = false;
          _deviceStatusController.add(deviceStatus);
          _subscribeToESenseEvents();
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

  /// Stellt eine Verbindung zum eSense-Gerät her, wenn nicht bereits verbunden.
  Future<void> _connectToESense() async {
    if (_eSenseManager == null || deviceStatus == 'Connected') return;

    try {
      final didConnect = await _eSenseManager!.connect();
      if (!didConnect) {
        deviceStatus = 'Connection failed';
        _deviceStatusController.add(deviceStatus);
      }
    } catch (e) {
      deviceStatus = 'Connection failed';
      _deviceStatusController.add(deviceStatus);
    }
  }

  /// Abonniert eSense-spezifische Events wie Batterie oder Button.
  void _subscribeToESenseEvents() {
    if (_eSenseManager == null || deviceStatus != 'Connected') return;

    try {
      _eSenseEventsSub = _eSenseManager!.eSenseEvents.listen((event) {
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
    } catch (e) {}
    _getESenseProperties();
  }

  /// Fragt periodisch Batterie und Gerätename ab.
  void _getESenseProperties() {
    Timer.periodic(
      const Duration(seconds: 10),
      (timer) => deviceStatus == 'Connected' ? _eSenseManager!.getBatteryVoltage() : null,
    );

    Timer(const Duration(seconds: 2), () => _eSenseManager!.getDeviceName());
  }

  /// Startet die Sensor-Events (IMU) und empfängt Beschleunigungsdaten.
  void startSensors() {
    if (_eSenseManager == null || deviceStatus != 'Connected') {
      return;
    }
    if (sampling) return;

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
          rawImuDataString = 'Accel: [${ax.toStringAsFixed(2)}, '
              '${ay.toStringAsFixed(2)}, ${az.toStringAsFixed(2)}]';
          currentMagnitude = mag;
          _dataController.add({
            'rawImuData': rawImuDataString,
            'currentMagnitude': currentMagnitude,
          });
          if (_accelSamples.length == _windowSize) {
            final magnitudes = _accelSamples.map((s) => s.magnitude).toList();
            final stdDev = _calculateStandardDeviation(magnitudes);
            if (stdDev > _movementThreshold && stdDev < _maxStdDev) {
              _updateMovementStatus('Bewegung');
            } else if (stdDev <= _movementThreshold) {
              _updateMovementStatus('Ruhig');
            }
          }
        }
      });
      sampling = true;
    } catch (e) {}
  }

  /// Stoppt die Sensor-Events und setzt alle Sensor-bezogenen Variablen zurück.
  void stopSensors() {
    _sensorSub?.cancel();
    _sensorSub = null;
    sampling = false;
    _accelSamples.clear();
    movementStatus = 'Ruhig';
    currentMagnitude = 0.0;
    rawImuDataString = 'No data';
    _movementStatusController.add(movementStatus);
    _buttonStatusController.add(button);
  }

  /// Aktualisiert den Bewegungsstatus und benachrichtigt die UI.
  void _updateMovementStatus(String status) {
    if (movementStatus != status) {
      movementStatus = status;
      _movementStatusController.add(movementStatus);
    }
  }

  /// Berechnet die Standardabweichung einer Liste von Werten.
  double _calculateStandardDeviation(List<double> data) {
    if (data.isEmpty) return 0.0;
    double mean = data.reduce((a, b) => a + b) / data.length;
    num sumOfSquaredDiffs = data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b);
    return sqrt(sumOfSquaredDiffs / data.length);
  }

  /// Trennt die Verbindung und setzt Statusvariablen zurück.
  Future<void> disconnect() async {
    stopSensors();
    await _eSenseManager?.disconnect();
    deviceStatus = 'Disconnected';
    sampling = false;
    movementStatus = 'Ruhig';
    currentMagnitude = 0.0;
    _accelSamples.clear();
    _deviceStatusController.add(deviceStatus);
    _movementStatusController.add(movementStatus);
    _buttonStatusController.add(button);
  }

  /// Schließt alle Streams und beendet die Sensor-Events.
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

/// Repräsentiert eine einzelne Messung mit Magnitude und Zeitstempel.
class _AccelSample {
  final double magnitude;
  final DateTime time;
  _AccelSample(this.magnitude, this.time);
}
