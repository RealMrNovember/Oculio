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
  double _scrollSensitivity = 1.35;

  @override
  void initState() {
    super.initState();
    _flowEngine = FlowScrollEngine(
      scrollController: _scrollController,
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

      _trackingService.configureScroll(
        lineHeightPx: _flowEngine.lineHeightPx,
        sensitivity: _scrollSensitivity,
      );

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

  void _onSensitivityChanged(double value) {
    setState(() {
      _scrollSensitivity = value;
      _trackingService.configureScroll(
        lineHeightPx: _flowEngine.lineHeightPx,
        sensitivity: value,
      );
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
    if (_tracking.isPaused) {
      return switch (_tracking.pauseReason) {
        PauseReason.noFace => 'PAUSED — No face',
        PauseReason.headTurned => 'PAUSED — Look away',
        PauseReason.eyesClosed => 'PAUSED — Eyes closed',
        PauseReason.manual => 'PAUSED — Manual',
        PauseReason.none => 'PAUSED',
      };
    }
    return switch (_tracking.gazeZone) {
      GazeZone.calibrating => 'CALIBRATING…',
      GazeZone.fixating => 'READING LINE',
      GazeZone.advance => 'SCROLL ↓',
      GazeZone.regress => 'SCROLL ↑',
      GazeZone.cooldown => 'READING LINE',
      GazeZone.holding => 'READING LINE',
    };
  }

  Color _statusColor() {
    if (_tracking.isPaused) {
      return switch (_tracking.pauseReason) {
        PauseReason.manual => Colors.orangeAccent,
        PauseReason.none => Colors.grey,
        _ => Colors.redAccent,
      };
    }
    return switch (_tracking.gazeZone) {
      GazeZone.advance => Colors.greenAccent,
      GazeZone.regress => Colors.lightBlueAccent,
      GazeZone.calibrating => Colors.amberAccent,
      _ => Colors.cyanAccent,
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
        appBar: AppBar(title: const Text('Oculio')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_initError!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final camera = _trackingService.controller;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        title: const Text('Oculio'),
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
              sensitivity: _scrollSensitivity,
              onSensitivityChanged: _onSensitivityChanged,
              onManualToggle: _handleTap,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: _CameraCorner(
              controller: camera,
              tracking: _tracking,
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraCorner extends StatelessWidget {
  const _CameraCorner({
    required this.controller,
    required this.tracking,
  });

  final CameraController? controller;
  final TrackingState tracking;

  @override
  Widget build(BuildContext context) {
    final faceOk = tracking.faceDetected;
    final borderColor = faceOk ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      width: 100,
      height: 132,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 2),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null && controller!.value.isInitialized)
            CameraPreview(controller!)
          else
            const ColoredBox(color: Colors.black54),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                faceOk ? 'FACE OK' : 'NO FACE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: borderColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebugPanel extends StatelessWidget {
  const _DebugPanel({
    required this.tracking,
    required this.sensitivity,
    required this.onSensitivityChanged,
    required this.onManualToggle,
  });

  final TrackingState tracking;
  final double sensitivity;
  final ValueChanged<double> onSensitivityChanged;
  final VoidCallback onManualToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.78),
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
              'Eye Y: ${(tracking.eyeNormalizedY * 100).toStringAsFixed(1)}%  |  '
              'Score: ${tracking.gazeScore.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            Text(
              'Zone: ${tracking.gazeZone.name}  |  '
              'Vel: ${tracking.scrollVelocityPxPerSec.toStringAsFixed(0)} px/s',
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 10),
            ),
            Text(
              'Face: ${tracking.faceDetected ? "YES" : "NO"}  |  '
              'Count: ${tracking.facesInFrame}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            Text(
              'Pipeline: ${tracking.pipelineStatus}',
              style: const TextStyle(color: Colors.amberAccent, fontSize: 10),
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
                const Text('Gain', style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: Slider(
                    value: sensitivity,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: sensitivity.toStringAsFixed(1),
                    onChanged: onSensitivityChanged,
                  ),
                ),
                Text(
                  sensitivity.toStringAsFixed(1),
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
