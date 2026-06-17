enum PauseReason {
  none,
  noFace,
  headTurned,
  eyesClosed,
  manual,
}

class TrackingState {
  const TrackingState({
    this.faceDetected = false,
    this.headEulerX = 0,
    this.headEulerY = 0,
    this.headEulerZ = 0,
    this.leftEyeOpenProbability = 1,
    this.rightEyeOpenProbability = 1,
    this.isPaused = true,
    this.pauseReason = PauseReason.manual,
    this.scrollSpeedMultiplier = 1,
    this.isProcessing = false,
  });

  final bool faceDetected;
  final double headEulerX;
  final double headEulerY;
  final double headEulerZ;
  final double leftEyeOpenProbability;
  final double rightEyeOpenProbability;
  final bool isPaused;
  final PauseReason pauseReason;
  final double scrollSpeedMultiplier;
  final bool isProcessing;

  double get averageEyeOpen =>
      (leftEyeOpenProbability + rightEyeOpenProbability) / 2;

  TrackingState copyWith({
    bool? faceDetected,
    double? headEulerX,
    double? headEulerY,
    double? headEulerZ,
    double? leftEyeOpenProbability,
    double? rightEyeOpenProbability,
    bool? isPaused,
    PauseReason? pauseReason,
    double? scrollSpeedMultiplier,
    bool? isProcessing,
  }) {
    return TrackingState(
      faceDetected: faceDetected ?? this.faceDetected,
      headEulerX: headEulerX ?? this.headEulerX,
      headEulerY: headEulerY ?? this.headEulerY,
      headEulerZ: headEulerZ ?? this.headEulerZ,
      leftEyeOpenProbability:
          leftEyeOpenProbability ?? this.leftEyeOpenProbability,
      rightEyeOpenProbability:
          rightEyeOpenProbability ?? this.rightEyeOpenProbability,
      isPaused: isPaused ?? this.isPaused,
      pauseReason: pauseReason ?? this.pauseReason,
      scrollSpeedMultiplier:
          scrollSpeedMultiplier ?? this.scrollSpeedMultiplier,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}
