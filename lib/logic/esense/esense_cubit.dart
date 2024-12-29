import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:esense_flutter/esense.dart';
import '../../data/repositories/esense_repository.dart';
part 'esense_state.dart';

class ESenseCubit extends Cubit<ESenseState> {
  final ESenseRepository esenseRepo;

  ESenseCubit({required this.esenseRepo}) : super(ESenseInitial());

  Future<void> connectToESense() async {
    emit(ESenseConnecting());
    print('** [ESenseCubit] connectToESense()');

    final success = await esenseRepo.connect(
      onConnectionEvent: (connEvent) {
        print('** [ESenseCubit] ConnectionEvent: $connEvent');
        if (connEvent.type == ConnectionType.connected) {
          emit(ESenseConnected());
        } else if (connEvent.type == ConnectionType.disconnected) {
          emit(ESenseDisconnected());
        } else if (connEvent.type == ConnectionType.device_not_found) {
          emit(ESenseError('Device not found.'));
        }
        // etc.
      },
      onSensorEvent: (sensorData) {
        //print('** [ESenseCubit] SensorEvent: $sensorData');
        emit(ESenseSensorData(sensorData));
      },
    );

    if (!success) {
      emit(ESenseError('Kein eSense gefunden!'));
      print('!! [ESenseCubit] -> kein eSense oder connect() fehlgeschlagen.');
    }
  }

  Future<void> disconnectESense() async {
    print('** [ESenseCubit] disconnectESense()');
    await esenseRepo.disconnect();
    emit(ESenseDisconnected());
  }
}

