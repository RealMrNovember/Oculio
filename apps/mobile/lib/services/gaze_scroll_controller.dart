import 'package:oculio_mobile/models/tracking_state.dart';

class GazeScrollResult {
  const GazeScrollResult({
    required this.velocityPxPerSec,
    required this.zone,
    this.gazeScore = 0,
    this.eyeNormalizedY = 0,
  });

  final double velocityPxPerSec;
  final GazeZone zone;
  final double gazeScore;
  final double eyeNormalizedY;
}

/// Eye-primary gaze proxy with inverted head pitch (head-up = scroll forward).
///
/// On most phones: lifting head tilts pitch down; bowing head tilts pitch up.
/// Eye landmarks shift vertically when the reader looks down/up within the face.
class GazeScrollController {
  double? _neutralPitch;
  double? _neutralEyeY;
  int _calibrationSamples = 0;
  double _smoothedPitch = 0;
  double _smoothedEyeY = 0;
  double _previousSmoothedPitch = 0;
  double _previousSmoothedEyeY = 0;
  DateTime? _lastAdvanceAt;

  static const int _calibrationTarget = 18;
  static const double _pitchSmoothing = 0.42;
  static const double _eyeSmoothing = 0.45;
  static const double _advanceScoreThreshold = 0.22;
  static const double _fixationScoreThreshold = 0.09;
  static const Duration _advanceCooldown = Duration(milliseconds: 220);

  void reset() {
    _neutralPitch = null;
    _neutralEyeY = null;
    _calibrationSamples = 0;
    _smoothedPitch = 0;
    _smoothedEyeY = 0;
    _previousSmoothedPitch = 0;
    _previousSmoothedEyeY = 0;
    _lastAdvanceAt = null;
  }

  GazeScrollResult compute({
    required double pitch,
    required double? eyeNormalizedY,
    required double lineHeightPx,
  }) {
    if (_smoothedPitch == 0) {
      _smoothedPitch = pitch;
    } else {
      _smoothedPitch =
          _smoothedPitch * (1 - _pitchSmoothing) + pitch * _pitchSmoothing;
    }

    final hasEye = eyeNormalizedY != null;
    if (hasEye) {
      if (_smoothedEyeY == 0) {
        _smoothedEyeY = eyeNormalizedY!;
      } else {
        _smoothedEyeY = _smoothedEyeY * (1 - _eyeSmoothing) +
            eyeNormalizedY! * _eyeSmoothing;
      }
    }

    if (_calibrationSamples < _calibrationTarget) {
      _neutralPitch = _neutralPitch == null
          ? pitch
          : (_neutralPitch! * _calibrationSamples + pitch) /
              (_calibrationSamples + 1);
      if (hasEye) {
        _neutralEyeY = _neutralEyeY == null
            ? eyeNormalizedY
            : (_neutralEyeY! * _calibrationSamples + eyeNormalizedY!) /
                (_calibrationSamples + 1);
      }
      _calibrationSamples++;
      _previousSmoothedPitch = _smoothedPitch;
      _previousSmoothedEyeY = _smoothedEyeY;
      return GazeScrollResult(
        velocityPxPerSec: 0,
        zone: GazeZone.calibrating,
        eyeNormalizedY: _smoothedEyeY,
      );
    }

    final pitchRate = _smoothedPitch - _previousSmoothedPitch;
    _previousSmoothedPitch = _smoothedPitch;

    final eyeRate = hasEye ? _smoothedEyeY - _previousSmoothedEyeY : 0.0;
    _previousSmoothedEyeY = _smoothedEyeY;

    // Head up → forward. Pitch usually drops when lifting head toward camera.
    final headScore = (-pitchRate) / 0.28;

    // Eyes move down in face image → forward scroll.
    final eyeDeltaFromNeutral = hasEye
        ? _smoothedEyeY - (_neutralEyeY ?? _smoothedEyeY)
        : 0.0;
    final eyeScore = (eyeRate / 0.0012) + (eyeDeltaFromNeutral / 0.018);

    final combined = hasEye
        ? eyeScore * 0.72 + headScore * 0.28
        : headScore;

    if (combined.abs() < _fixationScoreThreshold &&
        eyeRate.abs() < 0.0006 &&
        pitchRate.abs() < 0.18) {
      return GazeScrollResult(
        velocityPxPerSec: 0,
        zone: GazeZone.fixating,
        gazeScore: combined,
        eyeNormalizedY: _smoothedEyeY,
      );
    }

    if (combined > _advanceScoreThreshold) {
      final now = DateTime.now();
      if (_lastAdvanceAt != null &&
          now.difference(_lastAdvanceAt!) < _advanceCooldown) {
        return GazeScrollResult(
          velocityPxPerSec: 0,
          zone: GazeZone.cooldown,
          gazeScore: combined,
          eyeNormalizedY: _smoothedEyeY,
        );
      }
      _lastAdvanceAt = now;

      final intensity = combined.clamp(0.35, 2.4);
      return GazeScrollResult(
        velocityPxPerSec: lineHeightPx * 4.5 * intensity,
        zone: GazeZone.advance,
        gazeScore: combined,
        eyeNormalizedY: _smoothedEyeY,
      );
    }

    if (combined < -_advanceScoreThreshold) {
      final intensity = combined.abs().clamp(0.35, 2.0);
      return GazeScrollResult(
        velocityPxPerSec: -lineHeightPx * 3.5 * intensity,
        zone: GazeZone.regress,
        gazeScore: combined,
        eyeNormalizedY: _smoothedEyeY,
      );
    }

    return GazeScrollResult(
      velocityPxPerSec: 0,
      zone: GazeZone.holding,
      gazeScore: combined,
      eyeNormalizedY: _smoothedEyeY,
    );
  }
}
