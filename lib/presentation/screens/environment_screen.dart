import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:esense_flutter/esense.dart';
import 'package:permission_handler/permission_handler.dart';

/// Zeigt ausschließlich 6-Achsen-Sensordaten (IMU) von eSense an.
class EnvironmentScreen extends StatefulWidget {
  const EnvironmentScreen({Key? key}) : super(key: key);

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  // Hier kannst du deinen Gerätenamen anpassen oder via SettingsCubit holen.
  static const String eSenseDeviceName = 'eSense-0629';

  // eSense
  late ESenseManager eSenseManager;
  bool _connected = false;
  String _deviceStatus = '';
  String _deviceName = 'Unknown';
  double _voltage = -1;
  String _button = 'not pressed';
  bool _sampling = false;
  String _imuDataString = 'Noch keine Sensordaten';

  StreamSubscription? _sensorSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _eSenseEventsSubscription;

  @override
  void initState() {
    super.initState();
    eSenseManager = ESenseManager(eSenseDeviceName);
    _listenToESense();
  }

  @override
  void dispose() {
    _pauseListenToSensorEvents();
    _connectionSubscription?.cancel();
    _eSenseEventsSubscription?.cancel();
    eSenseManager.disconnect();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // eSense
  // ---------------------------------------------------------------------------

  Future<void> _askForPermissions() async {
    // Bluetooth-Permission anfragen (Android 12+)
    if (!(await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted)) {
      debugPrint(
          'WARNING - Keine Bluetooth-Berechtigung. eSense kann nicht verbunden werden.');
    }
    if (Platform.isAndroid) {
      // Für manche Geräte evtl. location-Berechtigung nötig
      if (!(await Permission.locationWhenInUse.request().isGranted)) {
        debugPrint(
            'WARNING - keine Standortberechtigung. eSense kann nicht verbunden werden.');
      }
    }
  }

  /// Baut Listener für Verbindungsevents auf.
  Future<void> _listenToESense() async {
    await _askForPermissions();

    // Verbindungsevents:
    _connectionSubscription = eSenseManager.connectionEvents.listen((event) {
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

  /// Verbindung starten
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

  /// Liest eSense-Events (z.B. DeviceName, Battery, Button, etc.).
  void _listenToESenseEvents() {
    _eSenseEventsSubscription = eSenseManager.eSenseEvents.listen((event) {
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
            // Beschleunigungs-Offsets, Config, etc. - kann man auslesen, falls gebraucht
            break;
        }
      });
    });

    _getESenseProperties();
  }

  /// Liest diverse Infos (Batterie, Name, etc.) mit Verzögerungen aus.
  void _getESenseProperties() {
    // Batterie alle 10s
    Timer.periodic(
      const Duration(seconds: 10),
      (timer) => (_connected) ? eSenseManager.getBatteryVoltage() : null,
    );

    Timer(const Duration(seconds: 2), () => eSenseManager.getDeviceName());
    Timer(const Duration(seconds: 3), () => eSenseManager.getAccelerometerOffset());
    Timer(const Duration(seconds: 4), () => eSenseManager.getAdvertisementAndConnectionInterval());
    Timer(const Duration(seconds: 15), () => eSenseManager.getSensorConfig());
  }

  /// Startet das Abhören der IMU-Daten
  void _startListenToSensorEvents() {
    // Frequenz vor dem Start (Beispiel):
    // eSenseManager.setSamplingRate(10);

    _sensorSubscription = eSenseManager.sensorEvents.listen((event) {
      // "SensorEvent" enthält x,y,z + Gyro, etc.
      // event.accel, event.gyro
      setState(() {
        _imuDataString =
            'Accel: [${event.accel?[0]}, ${event.accel?[1]}, ${event.accel?[2]}]\n'
            'Gyro: [${event.gyro?[0]}, ${event.gyro?[1]}, ${event.gyro?[2]}]';
      });
    });

    setState(() {
      _sampling = true;
    });
  }

  /// Stoppt das Abhören der SensorEvents
  void _pauseListenToSensorEvents() {
    _sensorSubscription?.cancel();
    setState(() {
      _sampling = false;
    });
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Umgebung (nur eSense IMU)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Gerätename (ausgelesen): $_deviceName'),
          Text('Verbindungsstatus: $_deviceStatus'),
          Text('Batterie: $_voltage V'),
          Text('Button: $_button'),
          const SizedBox(height: 10),
          Text('IMU-Daten:\n$_imuDataString'),
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
                child: Text(!_sampling ? 'Start Sensors' : 'Pause Sensors'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _connected
                    ? () {
                        eSenseManager.disconnect();
                        setState(() {
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
