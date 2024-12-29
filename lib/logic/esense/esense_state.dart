
part of 'esense_cubit.dart';

abstract class ESenseState {}

class ESenseInitial extends ESenseState {}
class ESenseConnecting extends ESenseState {}
class ESenseConnected extends ESenseState {}
class ESenseDisconnected extends ESenseState {}

class ESenseError extends ESenseState {
  final String message;
  ESenseError(this.message);
}

class ESenseSensorData extends ESenseState {
  final SensorEvent sensor;
  ESenseSensorData(this.sensor);
}