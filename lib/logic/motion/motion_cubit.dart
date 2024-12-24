import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'motion_state.dart';
import '../../data/repositories/motion_repository.dart';

class MotionCubit extends Cubit<MotionState> {
  final MotionRepository motionRepo;
  StreamSubscription? _subscription;

  MotionCubit({required this.motionRepo}) : super(MotionInitial());

  void startMonitoring() {
    emit(MotionListening());

    // Beispiel: motionRepo.startMonitoring(...) gibt einen Stream (x,y,z) zurück.
    _subscription = motionRepo.startMonitoring().listen((event) {
      // 'event' könnte z. B. (double x, double y, double z) sein
      final x = event.x;
      final y = event.y;
      final z = event.z;

      final magnitude = (x * x + y * y + z * z).toDouble(); 
      // oder sqrt(...) je nach Sensor

      // Schwellwert - z. B. 20 
      if (magnitude > 20.0) {
        emit(MotionTooActive(magnitude));
      } else {
        emit(MotionNormal(magnitude));
      }
    });
  }

  void stopMonitoring() {
    _subscription?.cancel();
    emit(MotionStopped());
  }
}
