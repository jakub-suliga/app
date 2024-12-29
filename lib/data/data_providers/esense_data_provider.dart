// lib/data/data_providers/esense_data_provider.dart

import 'package:esense_flutter/esense.dart';
import 'dart:async';

class ESenseDataProvider {
  final String deviceName;
  late ESenseManager _manager;

  final StreamController<ESenseEvent> _deviceStreamController =
      StreamController<ESenseEvent>.broadcast();
  final StreamController<SensorEvent> _sensorStreamController =
      StreamController<SensorEvent>.broadcast();

  /// Externe Streams zum Anhören
  Stream<ESenseEvent> get deviceEvents => _deviceStreamController.stream;
  Stream<SensorEvent> get sensorEvents => _sensorStreamController.stream;

  ESenseDataProvider({required this.deviceName}) {
    _manager = ESenseManager(deviceName);
  }

  /// Verbindung aufbauen
  Future<bool> connect() async {
    bool success = await _manager.connect();
    if (success) {
      // eSenseEvents abonnieren
      _manager.eSenseEvents.listen((esenseEvent) {
        _deviceStreamController.add(esenseEvent);
      });

      // SensorEvents abonnieren
      _manager.sensorEvents.listen((sensorEvent) {
        _sensorStreamController.add(sensorEvent);
      });
    }
    return success;
  }

  /// Sampling Rate einstellen
  Future<void> setSamplingRate(int rate) async {
    await _manager.setSamplingRate(rate);
  }

  /// Verbindung trennen
  Future<void> disconnect() async {
    await _manager.disconnect();
    await _deviceStreamController.close();
    await _sensorStreamController.close();
  }
}
