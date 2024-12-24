import 'dart:async';
import '../data_providers/motion_data_provider.dart';

/// Repräsentiert eine einfache "MotionEvent", z. B. (x, y, z)
class MotionEvent {
  final double x;
  final double y;
  final double z;
  MotionEvent(this.x, this.y, this.z);
}

class MotionRepository {
  final MotionDataProvider dataProvider;

  MotionRepository({required this.dataProvider});

  /// Startet das Monitoring und gibt einen Stream von 'MotionEvent' zurück.
  Stream<MotionEvent> startMonitoring() {
    // Wir kombinieren die AccelerometerEvents hier nur als Beispiel.
    // Falls du GyroscopeEvent auch brauchst, müsstest du kombinieren.
    return dataProvider.accelerometerStream.map((event) {
      return MotionEvent(event.x, event.y, event.z);
    });
  }

  /// In diesem Skeleton beenden wir nur den Stream, 
  /// tatsächlich müsstest du in DataProvider evtl. was stoppen.
  void stopMonitoring() {
    // Falls du in DataProvider was beenden willst:
    // dataProvider.stopSensors()  o.ä.
  }
}

