import 'dart:async';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';

class VolumeDataProvider {
  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _noiseSubscription;
  bool isRecording = false;

  VolumeDataProvider() {
    // _noiseMeter wird in startListening() initialisiert
  }

  /// Startet das Abhören der Mikrofon-Lautstärke.
  /// Hier bauen wir nun die Permission-Abfrage ein.
  Future<void> startListening({
    required void Function(NoiseReading) onData,
    void Function(Object)? onError,
  }) async {
    // 1) Mikrofonberechtigung prüfen/anfragen
    final status = await Permission.microphone.status;
    if (status.isDenied || status.isRestricted) {
      final requestResult = await Permission.microphone.request();
      if (!requestResult.isGranted) {
        onError?.call('Mikrofon-Berechtigung abgelehnt');
        return; // abbrechen, da keine Berechtigung
      }
    }

    // 2) NoiseMeter erst hier instanzieren
    _noiseMeter = NoiseMeter();

    // 3) StreamSubscription auf den Stream .noise setzen
    _noiseSubscription = _noiseMeter!.noise.listen(
      (reading) => onData(reading),
      onError: (error) => onError?.call(error),
    );

    isRecording = true;
  }

  /// Stoppt das Abhören der Mikrofon-Lautstärke.
  Future<void> stopListening() async {
    await _noiseSubscription?.cancel();
    _noiseSubscription = null;
    _noiseMeter = null;
    isRecording = false;
  }
}
