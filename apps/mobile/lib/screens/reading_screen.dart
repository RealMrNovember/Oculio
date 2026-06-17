import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:oculio_mobile/data/sample_text.dart';
import 'package:oculio_mobile/models/tracking_state.dart';
import 'package:oculio_mobile/services/face_tracking_service.dart';
import 'package:oculio_mobile/services/flow_scroll_engine.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final FaceTrackingService _trackingService = FaceTrackingService();
  final ScrollController _scrollController = ScrollController();
  late final FlowScrollEngine _flowEngine;

  bool _initializing = true;
  String? _initError;
  TrackingState _tracking = const TrackingState(isPaused: true);
  double _wpm = 200;

  @override
  void initState() {
    super.initState();
    _flowEngine = FlowScrollEngine(
      scrollController: _scrollController,
      baseWpm: _wpm,
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final ok = await _trackingService.initialize();
      if (!ok) {
        setState(() {
          _initError = 'Camera permission is required for Phase 0 testing.';
          _initializing = false;
        });
        return;
      }

      await _trackingService.start((state) {
        if (!mounted) return;
        setState(() => _tracking = state);
        _flowEngine.updateTracking(state);
      });

      _flowEngine.start();
      setState(() => _initializing = false);
    } catch (error) {
      setState(() {
        _initError = 'Failed to start camera: $error';
        _initializing = false;
      });
    }
  }

  @override
  void dispose() {
    _flowEngine.dispose();
    _scrollController.dispose();
    _trackingService.dispose();
    super.dispose();
  }

  void _onWpmChanged(double value) {
    setState(() {
      _wpm = value;
      _flowEngine.baseWpm = value;
    });
  }

  void _handleTap() {
    final isManualPaused =
        _tracking.isPaused && _tracking.pauseReason == PauseReason.manual;
    if (isManualPaused) {
      _trackingService.setManualPause(false);
    } else {
      _trackingService.setManualPause(true);
      _flowEngine.pauseManually();
    }
    setState(() => _tracking = _trackingService.state);
  }

  String _pauseLabel() {
    if (!_tracking.isPaused) return 'READING';
    return switch (_tracking.pauseReason) {
      PauseReason.noFace => 'PAUSED — No face',
      PauseReason.headTurned => 'PAUSED — Look away',
      PauseReason.eyesClosed => 'PAUSED — Eyes closed',
      PauseReason.manual => 'PAUSED — Manual',
      PauseReason.none => 'PAUSED',
    };
  }

  Color _statusColor() {
    if (!_tracking.isPaused) return Colors.greenAccent;
    return switch (_tracking.pauseReason) {
      PauseReason.manual => Colors.orangeAccent,
      PauseReason.none => Colors.grey,
      _ => Colors.redAccent,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Starting camera & ML Kit…'),
            ],
          ),
        ),
      );
    }

    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Oculio Phase 0')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_initError!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final preview = _trackingService.controller;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        title: const Text('Oculio Flow — Phase 0'),
        backgroundColor: const Color(0xFF1A2332),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                _pauseLabel(),
                style: TextStyle(
                  color: _statusColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: _handleTap,
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Text(
                  kPhase0SampleText,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.6,
                    color: Colors.grey.shade100,
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _DebugPanel(
              tracking: _tracking,
              wpm: _wpm,
              onWpmChanged: _onWpmChanged,
              onManualToggle: _handleTap,
            ),
          ),
          if (preview != null && preview.value.isInitialized)
            Positioned(
              top: 8,
              right: 8,
              child: _CameraPreviewBadge(controller: preview),
            ),
        ],
      ),
    );
  }
}

class _CameraPreviewBadge extends StatelessWidget {
  const _CameraPreviewBadge({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 128,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      clipBehavior: Clip.hardEdge,
      child: CameraPreview(controller),
    );
  }
}

class _DebugPanel extends StatelessWidget {
  const _DebugPanel({
    required this.tracking,
    required this.wpm,
    required this.onWpmChanged,
    required this.onManualToggle,
  });

  final TrackingState tracking;
  final double wpm;
  final ValueChanged<double> onWpmChanged;
  final VoidCallback onManualToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.78),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'DEBUG — ML Kit',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Face: ${tracking.faceDetected ? "YES" : "NO"}  |  '
              'Scroll ×${tracking.scrollSpeedMultiplier.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              'Pitch X: ${tracking.headEulerX.toStringAsFixed(1)}°  '
              'Yaw Y: ${tracking.headEulerY.toStringAsFixed(1)}°  '
              'Roll Z: ${tracking.headEulerZ.toStringAsFixed(1)}°',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            Text(
              'Eye L: ${(tracking.leftEyeOpenProbability * 100).toStringAsFixed(0)}%  '
              'R: ${(tracking.rightEyeOpenProbability * 100).toStringAsFixed(0)}%  '
              'Avg: ${(tracking.averageEyeOpen * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('WPM', style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: Slider(
                    value: wpm,
                    min: 80,
                    max: 350,
                    divisions: 27,
                    label: wpm.round().toString(),
                    onChanged: onWpmChanged,
                  ),
                ),
                Text(
                  wpm.round().toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onManualToggle,
                child: const Text('Tap text or here to toggle manual pause'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
