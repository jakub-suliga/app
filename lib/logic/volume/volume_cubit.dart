import 'package:flutter_bloc/flutter_bloc.dart';
import 'volume_state.dart';

class VolumeCubit extends Cubit<VolumeState> {
  VolumeCubit() : super(VolumeInitial());

  void updateVolume(double decibel) {
    if (decibel < 50) {
      emit(VolumeNormal(decibel: decibel));
    } else {
      emit(VolumeTooHigh(decibel: decibel));
    }
  }

  // ... andere Methoden und Logik
}
