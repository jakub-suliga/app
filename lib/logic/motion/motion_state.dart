abstract class MotionState {}

class MotionInitial extends MotionState {}

class MotionListening extends MotionState {}

class MotionNormal extends MotionState {
  final double magnitude;
  MotionNormal(this.magnitude);
}

class MotionTooActive extends MotionState {
  final double magnitude;
  MotionTooActive(this.magnitude);
}

class MotionStopped extends MotionState {}
