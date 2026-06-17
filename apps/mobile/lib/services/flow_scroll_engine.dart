import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oculio_mobile/models/tracking_state.dart';

/// Applies gaze-driven velocity only — never continuous WPM while face is visible.
class FlowScrollEngine {
  FlowScrollEngine({
    required this.scrollController,
    this.fontSize = 20,
    this.lineHeight = 1.6,
  });

  final ScrollController scrollController;
  final double fontSize;
  final double lineHeight;

  Timer? _timer;
  TrackingState _tracking = const TrackingState();
  bool _userOverride = false;
  DateTime? _overrideUntil;
  DateTime? _lastVelocityAt;

  static const int _tickMs = 50;

  double get _lineHeightPx => fontSize * lineHeight;

  void updateTracking(TrackingState tracking) {
    _tracking = tracking;
    if (tracking.scrollVelocityPxPerSec != 0) {
      _lastVelocityAt = DateTime.now();
    }
    if (!tracking.isPaused && tracking.gazeZone == GazeZone.fixating) {
      _userOverride = false;
    }
  }

  void start() {
    _timer ??= Timer.periodic(
      const Duration(milliseconds: _tickMs),
      (_) => _tick(),
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void pauseManually({Duration duration = const Duration(seconds: 10)}) {
    _userOverride = true;
    _overrideUntil = DateTime.now().add(duration);
  }

  void _tick() {
    if (!scrollController.hasClients) return;

    if (_userOverride) {
      if (_overrideUntil != null && DateTime.now().isBefore(_overrideUntil!)) {
        return;
      }
      _userOverride = false;
    }

    if (_tracking.isPaused) return;

    var velocity = _tracking.scrollVelocityPxPerSec;
    if (_lastVelocityAt != null &&
        DateTime.now().difference(_lastVelocityAt!) >
            const Duration(milliseconds: 100)) {
      velocity = 0;
    }

    if (velocity == 0) return;

    final delta = velocity * (_tickMs / 1000);
    final maxScroll = scrollController.position.maxScrollExtent;
    final next = (scrollController.offset + delta).clamp(0.0, maxScroll);
    if (next >= maxScroll) {
      stop();
      return;
    }
    scrollController.jumpTo(next);
  }

  double get lineHeightPx => _lineHeightPx;

  void dispose() {
    stop();
  }
}
