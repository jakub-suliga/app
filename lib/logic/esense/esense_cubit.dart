import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:esense_flutter/esense.dart';
import '../../data/repositories/esense_repository.dart';
part 'esense_state.dart';

class ESenseCubit extends Cubit<ESenseState> {
  final ESenseRepository esenseRepo;

  ESenseCubit({required this.esenseRepo}) : super(ESenseInitial());

  /// Verbindung starten
  Future<void> connectToESense() async {
    emit(ESenseConnecting());

    bool success = await esenseRepo.connect(
      onDeviceEvent: (event) {
        // Falls Battery, Button etc. => 
        // hier könntest du den State anpassen oder Logik abbilden
      },
      onSensorEvent: (sensorData) {
        // Hier IMU-Daten => Accel / Gyro
        emit(ESenseSensorData(sensorData));
      },
    );

    if (!success) {
      emit(ESenseError("Verbindung zu eSense nicht möglich"));
    } else {
      // Sobald connect() true zurückgibt, 
      // warten wir auf ConnectionType-Bestätigung.
      // Du könntest hier optional ESenseConnected() emitten – 
      // oder du hörst in onDeviceEvent auf ConnectionType.connected.
    }
  }

  Future<void> disconnectESense() async {
    await esenseRepo.disconnect();
    emit(ESenseDisconnected());
  }

  Future<void> setSamplingRate(int rate) async {
    try {
      await esenseRepo.setSamplingRate(rate);
    } catch (e) {
      emit(ESenseError(e.toString()));
    }
  }
}
