// lib/data/repositories/esense_repository.dart

import '../data_providers/esense_data_provider.dart';
import 'package:esense_flutter/esense.dart';
import 'dart:async';

class ESenseRepository {
  final ESenseDataProvider dataProvider;
  StreamSubscription<ESenseEvent>? _deviceSub;
  StreamSubscription<SensorEvent>? _sensorSub;

  ESenseRepository({required this.dataProvider});

  /// Verbindung aufbauen und Callback-Funktionen registrieren
  Future<bool> connect({
    void Function(ESenseEvent)? onDeviceEvent,
    void Function(SensorEvent)? onSensorEvent,
  }) async {
    bool success = await dataProvider.connect();
    if (success) {
      if (onDeviceEvent != null) {
        _deviceSub = dataProvider.deviceEvents.listen(onDeviceEvent);
      }
      if (onSensorEvent != null) {
        _sensorSub = dataProvider.sensorEvents.listen(onSensorEvent);
      }
    }
    return success;
  }

  Future<void> setSamplingRate(int rate) async {
    await dataProvider.setSamplingRate(rate);
  }

  Future<void> disconnect() async {
    await _deviceSub?.cancel();
    await _sensorSub?.cancel();
    await dataProvider.disconnect();
  }
}
