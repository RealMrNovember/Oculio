enum PauseReason {
  none,
  noFace,
  headTurned,
  eyesClosed,
  manual,
}

enum ReadingMode {
  /// Gaze-proxy scroll — moves only on look-down.
  eyeAssist,

  /// ML unavailable — manual scroll only.
  wpmFallback,

  manual,
}

enum GazeZone {
  calibrating,
  fixating,
  holding,
  advance,
  regress,
  cooldown,
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
    this.scrollVelocityPxPerSec = 0,
    this.gazeZone = GazeZone.holding,
    this.isProcessing = false,
    this.pipelineStatus = 'idle',
    this.facesInFrame = 0,
    this.readingMode = ReadingMode.eyeAssist,
    this.framesProcessed = 0,
    this.gazeScore = 0,
    this.eyeNormalizedY = 0,
  });

  final bool faceDetected;
  final double headEulerX;
  final double headEulerY;
  final double headEulerZ;
  final double leftEyeOpenProbability;
  final double rightEyeOpenProbability;
  final bool isPaused;
  final PauseReason pauseReason;
  final double scrollVelocityPxPerSec;
  final GazeZone gazeZone;
  final bool isProcessing;
  final String pipelineStatus;
  final int facesInFrame;
  final ReadingMode readingMode;
  final int framesProcessed;
  final double gazeScore;
  final double eyeNormalizedY;

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
    double? scrollVelocityPxPerSec,
    GazeZone? gazeZone,
    bool? isProcessing,
    String? pipelineStatus,
    int? facesInFrame,
    ReadingMode? readingMode,
    int? framesProcessed,
    double? gazeScore,
    double? eyeNormalizedY,
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
      scrollVelocityPxPerSec:
          scrollVelocityPxPerSec ?? this.scrollVelocityPxPerSec,
      gazeZone: gazeZone ?? this.gazeZone,
      isProcessing: isProcessing ?? this.isProcessing,
      pipelineStatus: pipelineStatus ?? this.pipelineStatus,
      facesInFrame: facesInFrame ?? this.facesInFrame,
      readingMode: readingMode ?? this.readingMode,
      framesProcessed: framesProcessed ?? this.framesProcessed,
      gazeScore: gazeScore ?? this.gazeScore,
      eyeNormalizedY: eyeNormalizedY ?? this.eyeNormalizedY,
    );
  }
}
