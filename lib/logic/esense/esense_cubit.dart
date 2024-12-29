import 'package:flutter_bloc/flutter_bloc.dart';

part 'esense_state.dart';

class ESenseCubit extends Cubit<ESenseConnectionState> {
  ESenseCubit() : super(ESenseConnectionInitial());

  /// Beispielmethode: Verbindung starten
  Future<void> connectToESense() async {
    emit(ESenseConnectionConnecting());

    // Hier würdest du die eigentliche Connect-Logik einbauen, z.B.:
    // bool success = await myDataProviderOrManager.connect();
    bool success = true; // Platzhalter

    if (success) {
      emit(ESenseConnectionConnected());
    }
  }

  /// Beispielmethode: Verbindung trennen
  Future<void> disconnectESense() async {
    // Hier ggf. Manager.disconnect()
    emit(ESenseConnectionDisconnected());
  }
}

