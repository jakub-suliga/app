part of 'esense_cubit.dart';

abstract class ESenseState {}

class ESenseInitial extends ESenseState {}
class ESenseConnecting extends ESenseState {}
class ESenseDisconnected extends ESenseState {}
class ESenseError extends ESenseState {
  final String message;
  ESenseError(this.message);
}

/// Falls du an dieser Stelle das "Connected" signalisieren willst:
class ESenseConnected extends ESenseState {}

/// Wenn IMU-Daten empfangen werden:
class ESenseSensorData extends ESenseState {
  final SensorEvent sensor;
  ESenseSensorData(this.sensor);
}
