import 'package:flutter_test/flutter_test.dart';
import 'package:oculio_mobile/models/tracking_state.dart';
import 'package:oculio_mobile/services/gaze_scroll_controller.dart';

void main() {
  test('stable gaze fixates with zero velocity', () {
    final gaze = GazeScrollController();
    for (var i = 0; i < 20; i++) {
      gaze.compute(pitch: 10, eyeNormalizedY: 0.42, lineHeightPx: 32);
    }
    final result = gaze.compute(pitch: 10, eyeNormalizedY: 0.42, lineHeightPx: 32);
    expect(result.velocityPxPerSec, 0);
    expect(result.zone, GazeZone.fixating);
  });

  test('head lift scrolls forward (inverted pitch)', () {
    final gaze = GazeScrollController();
    for (var i = 0; i < 20; i++) {
      gaze.compute(pitch: 12, eyeNormalizedY: 0.42, lineHeightPx: 32);
    }
    // Head up → pitch drops
    final result = gaze.compute(pitch: 8, eyeNormalizedY: 0.42, lineHeightPx: 32);
    expect(result.velocityPxPerSec, greaterThan(0));
    expect(result.zone, GazeZone.advance);
  });

  test('eyes down scrolls forward', () {
    final gaze = GazeScrollController();
    for (var i = 0; i < 20; i++) {
      gaze.compute(pitch: 10, eyeNormalizedY: 0.40, lineHeightPx: 32);
    }
    final result = gaze.compute(pitch: 10, eyeNormalizedY: 0.46, lineHeightPx: 32);
    expect(result.velocityPxPerSec, greaterThan(0));
    expect(result.zone, GazeZone.advance);
  });
}
