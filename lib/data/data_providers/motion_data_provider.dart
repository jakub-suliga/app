import 'package:sensors_plus/sensors_plus.dart';

class MotionDataProvider {
  Stream<AccelerometerEvent> get accelerometerStream => accelerometerEvents;
  Stream<GyroscopeEvent> get gyroscopeStream => gyroscopeEvents;

  // Hier könntest du Bewegungsanalysen durchführen.
}
