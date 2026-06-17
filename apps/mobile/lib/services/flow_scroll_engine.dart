import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oculio_mobile/models/tracking_state.dart';

/// Hybrid WPM auto-scroll modulated by gaze-proxy multiplier from face tracking.
class FlowScrollEngine {
  FlowScrollEngine({
    required this.scrollController,
    this.baseWpm = 200,
    this.fontSize = 20,
    this.lineHeight = 1.6,
  });

  final ScrollController scrollController;
  double baseWpm;
  final double fontSize;
  final double lineHeight;

  Timer? _timer;
  TrackingState _tracking = const TrackingState(isPaused: true);
  bool _userOverride = false;
  DateTime? _overrideUntil;

  static const int _tickMs = 50;

  void updateTracking(TrackingState tracking) {
    _tracking = tracking;
    if (!tracking.isPaused) {
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

    final pixelsPerWord = fontSize * lineHeight * 0.45;
    final wordsPerSecond = baseWpm / 60;
    final basePixelsPerSecond = wordsPerSecond * pixelsPerWord;
    final speed = basePixelsPerSecond * _tracking.scrollSpeedMultiplier;
    final delta = speed * (_tickMs / 1000);

    final maxScroll = scrollController.position.maxScrollExtent;
    final next = (scrollController.offset + delta).clamp(0.0, maxScroll);
    if (next >= maxScroll) {
      stop();
      return;
    }
    scrollController.jumpTo(next);
  }

  void dispose() {
    stop();
  }
}
