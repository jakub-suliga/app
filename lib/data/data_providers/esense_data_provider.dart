import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:esense_flutter/esense.dart';

class ESenseDataProvider {
  ESenseManager? _manager;

  // Streams
  final _connStreamController = StreamController<ConnectionEvent>.broadcast();
  final _deviceStreamController = StreamController<ESenseEvent>.broadcast();
  final _sensorStreamController = StreamController<SensorEvent>.broadcast();

  Stream<ConnectionEvent> get connectionEvents => _connStreamController.stream;
  Stream<ESenseEvent> get deviceEvents => _deviceStreamController.stream;
  Stream<SensorEvent> get sensorEvents => _sensorStreamController.stream;

  ESenseDataProvider();

  Future<void> _askForPermissions() async {
    // Bluetooth-Permission
    if (!(await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted)) {
      print('!! [ESenseDataProvider] Keine BLE-Permissions gewährt.');
    }

    // Location für Android
    if (Platform.isAndroid) {
      if (!(await Permission.locationWhenInUse.request().isGranted)) {
        print('!! [ESenseDataProvider] Keine Location-Permission.');
      }
    }
  }

  /// Verbindet sich mit dem eSense-Gerät [deviceName], z. B. "eSense-0598".
  Future<bool> connectToName(String deviceName) async {
    print('** [ESenseDataProvider] connectToName("$deviceName") aufgerufen.');
    await _askForPermissions();

    _manager = ESenseManager(deviceName);

    // connectionEvents
    _manager!.connectionEvents.listen((connEvent) {
      print('** [ESenseDataProvider] ConnectionEvent: $connEvent');
      _connStreamController.add(connEvent);
    });

    // eSenseEvents
    _manager!.eSenseEvents.listen((event) {
      print('** [ESenseDataProvider] eSenseEvent: $event');
      _deviceStreamController.add(event);
    });

    // SensorEvents
    _manager!.sensorEvents.listen((sensorEvent) {
      //print('** [ESenseDataProvider] SensorEvent: $sensorEvent');
      _sensorStreamController.add(sensorEvent);
    });

    final success = await _manager!.connect();
    print('** [ESenseDataProvider] connect() -> $success');
    return success;
  }

  Future<void> disconnect() async {
    print('** [ESenseDataProvider] disconnect() aufgerufen.');

    if (_manager != null && _manager!.connected) {
      print('** [ESenseDataProvider] -> disconnect() vom eSense.');
      await _manager!.disconnect();
    }

    await _connStreamController.close();
    await _deviceStreamController.close();
    await _sensorStreamController.close();
  }
}
