import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class ESenseScanner {
  final FlutterReactiveBle _ble;

  ESenseScanner() : _ble = FlutterReactiveBle();

  /// Startet einen Scan nach BLE-Geräten für [timeoutSeconds].
  /// Erfasst *alle* Geräte (kein Service-Filter), 
  /// scannt im Modus [ScanMode.lowLatency].
  /// 
  /// Sobald ein Name gefunden wird, der mit "eSense-" beginnt, 
  /// geben wir diesen Namen zurück. Läuft [timeoutSeconds] ab, 
  /// ohne Fund -> `null`.
  Future<String?> scanForESense({int timeoutSeconds = 15}) async {
    print('** [ESenseScanner] Starte Scan via flutter_reactive_ble (max. $timeoutSeconds s).');

    final completer = Completer<String?>();
    // scanForDevices => Stream von DiscoveredDevice
    final subscription = _ble
        .scanForDevices(
          withServices: [], // kein spezieller Service-Filter
          scanMode: ScanMode.lowLatency, // aggressiver / häufiger Scan
        )
        .listen(
      (device) {
        final deviceName = device.name;
        // Loggen aller gefundenen Geräte
        print('** [ESenseScanner] Gefunden: $deviceName (id: ${device.id}), RSSI: ${device.rssi}');

        // Prüfen, ob Name "eSense-" prefix hat
        if (deviceName.startsWith('eSense-')) {
          if (!completer.isCompleted) {
            print('** [ESenseScanner] -> Erster eSense-Treffer: $deviceName');
            completer.complete(deviceName);
          }
        }
      },
      onError: (err, stack) {
        print('!! [ESenseScanner] Scan-Fehler: $err');
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );

    // Timeout => nach [timeoutSeconds] brechen wir ab, falls kein eSense gefunden
    Future.delayed(Duration(seconds: timeoutSeconds), () {
      if (!completer.isCompleted) {
        print('** [ESenseScanner] Scan Timeout - kein eSense gefunden.');
        completer.complete(null);
      }
    });

    final deviceName = await completer.future;

    // Scan beenden
    await subscription.cancel();
    print('** [ESenseScanner] Scan beendet.');

    return deviceName;
  }
}
