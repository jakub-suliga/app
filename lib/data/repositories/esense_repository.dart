import 'dart:async';
import 'package:esense_flutter/esense.dart';
import '../data_providers/esense_scanner.dart';
import '../data_providers/esense_data_provider.dart';

class ESenseRepository {
  final ESenseScanner scanner;
  final ESenseDataProvider dataProvider;

  StreamSubscription<ConnectionEvent>? _connSub;
  StreamSubscription<ESenseEvent>? _deviceSub;
  StreamSubscription<SensorEvent>? _sensorSub;

  ESenseRepository({
    required this.scanner,
    required this.dataProvider,
  });

  /// Scannt via [scanner] nach "eSense-XXXX".
  /// Falls gefunden, ruft [dataProvider.connectToName] auf.
  Future<bool> connect({
    void Function(ConnectionEvent)? onConnectionEvent,
    void Function(ESenseEvent)? onDeviceEvent,
    void Function(SensorEvent)? onSensorEvent,
  }) async {
    print('** [ESenseRepository] Starte Scan -> eSense Connect()');
    final foundName = await scanner.scanForESense(timeoutSeconds: 5);

    if (foundName == null) {
      print('!! [ESenseRepository] Kein eSense-Gerät gefunden!');
      return false;
    }
    print('** [ESenseRepository] Gefunden: $foundName -> connectToName(...)');

    final success = await dataProvider.connectToName(foundName);
    if (success) {
      print('** [ESenseRepository] connect() erfolgreich gestartet.');
      // Streams abonnieren
      if (onConnectionEvent != null) {
        _connSub = dataProvider.connectionEvents.listen(onConnectionEvent);
      }
      if (onDeviceEvent != null) {
        _deviceSub = dataProvider.deviceEvents.listen(onDeviceEvent);
      }
      if (onSensorEvent != null) {
        _sensorSub = dataProvider.sensorEvents.listen(onSensorEvent);
      }
    } else {
      print('!! [ESenseRepository] connectToName($foundName) = false');
    }

    return success;
  }

  Future<void> disconnect() async {
    print('** [ESenseRepository] disconnect()');
    await _connSub?.cancel();
    await _deviceSub?.cancel();
    await _sensorSub?.cancel();
    await dataProvider.disconnect();
  }
}
