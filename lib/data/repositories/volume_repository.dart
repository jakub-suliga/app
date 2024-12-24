import 'dart:async';
import 'package:noise_meter/noise_meter.dart';
import '../data_providers/volume_data_provider.dart';

class VolumeRepository {
  final VolumeDataProvider dataProvider;

  VolumeRepository({required this.dataProvider});

  /// Startet das Abhören der Lautstärke und ruft [onNoiseLevel] bei jedem Messwert auf.
  /// Optional kannst du [onError] übergeben, falls Fehler abgefangen werden sollen.
  Future<void> startVolumeListening(
    void Function(double) onNoiseLevel, {
    void Function(Object)? onError,
  }) async {
    await dataProvider.startListening(
      onData: (NoiseReading reading) {
        onNoiseLevel(reading.maxDecibel);
      },
      onError: onError,
    );
  }

  /// Beendet das Abhören der Lautstärke.
  Future<void> stopVolumeListening() async {
    await dataProvider.stopListening();
  }
}
