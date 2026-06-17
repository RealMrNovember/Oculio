import 'package:flutter_test/flutter_test.dart';
import 'package:oculio_mobile/models/tracking_state.dart';

void main() {
  test('averageEyeOpen calculates mean of both eyes', () {
    const state = TrackingState(
      leftEyeOpenProbability: 0.8,
      rightEyeOpenProbability: 0.6,
    );
    expect(state.averageEyeOpen, closeTo(0.7, 0.001));
  });
}
