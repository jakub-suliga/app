abstract class VolumeState {
  final double decibel;
  VolumeState(this.decibel);
}

class VolumeInitial extends VolumeState {
  VolumeInitial() : super(0.0);
}

class VolumeNormal extends VolumeState {
  VolumeNormal({required double decibel}) : super(decibel);
}

class VolumeTooHigh extends VolumeState {
  VolumeTooHigh({required double decibel}) : super(decibel);
}
