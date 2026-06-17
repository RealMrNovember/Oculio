import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:oculio_mobile/models/tracking_state.dart';
import 'package:oculio_mobile/utils/camera_image_converter.dart';
import 'package:permission_handler/permission_handler.dart';

typedef TrackingCallback = void Function(TrackingState state);

/// Front-camera + ML Kit face pipeline producing gaze-proxy signals.
class FaceTrackingService {
  FaceTrackingService();

  static const double yawPauseThreshold = 32;
  static const double yawResumeThreshold = 22;
  static const double eyeClosedThreshold = 0.28;
  static const double eyeOpenThreshold = 0.55;
  static const double pitchBoostStart = 8;
  static const double pitchBoostMax = 28;

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.12,
    ),
  );

  CameraController? _controller;
  bool _isStreaming = false;
  bool _manualPause = false;
  bool _resumePending = false;
  DateTime? _resumeAfter;
  int _frameSkip = 0;
  TrackingState _state = const TrackingState(isPaused: true);

  CameraController? get controller => _controller;
  TrackingState get state => _state;

  Future<bool> initialize() async {
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      debugPrint('[FaceTracking] Camera permission denied');
      return false;
    }

    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      front,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    return true;
  }

  Future<void> start(TrackingCallback onUpdate) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isStreaming) return;

    _isStreaming = true;
    await _controller!.startImageStream((image) async {
      if (!_isStreaming) return;

      // Process ~12 FPS to reduce heat.
      _frameSkip = (_frameSkip + 1) % 2;
      if (_frameSkip != 0) return;
      if (_state.isProcessing) return;

      _state = _state.copyWith(isProcessing: true);
      onUpdate(_state);

      try {
        final inputImage = inputImageFromCameraImage(
          image,
          _controller!.description,
          _controller!.value.deviceOrientation,
        );

        if (inputImage == null) {
          _applyNoFace(onUpdate);
          return;
        }

        final faces = await _detector.processImage(inputImage);
        if (faces.isEmpty) {
          _applyNoFace(onUpdate);
          return;
        }

        final face = faces.first;
        final next = _evaluateFace(face);
        _state = next;
        onUpdate(_state);
      } catch (error, stack) {
        debugPrint('[FaceTracking] frame error: $error\n$stack');
      } finally {
        _state = _state.copyWith(isProcessing: false);
      }
    });
  }

  void _applyNoFace(TrackingCallback onUpdate) {
    _state = _state.copyWith(
      faceDetected: false,
      isPaused: true,
      pauseReason: PauseReason.noFace,
      scrollSpeedMultiplier: 0,
      isProcessing: false,
    );
    _resumePending = false;
    onUpdate(_state);
  }

  TrackingState _evaluateFace(Face face) {
    final yaw = face.headEulerAngleY ?? 0;
    final pitch = face.headEulerAngleX ?? 0;
    final roll = face.headEulerAngleZ ?? 0;
    final leftEye = face.leftEyeOpenProbability ?? 1;
    final rightEye = face.rightEyeOpenProbability ?? 1;
    final avgEye = (leftEye + rightEye) / 2;

    final headTurned = yaw.abs() > yawPauseThreshold;
    final eyesClosed = avgEye < eyeClosedThreshold;

    if (_manualPause) {
      return TrackingState(
        faceDetected: true,
        headEulerX: pitch,
        headEulerY: yaw,
        headEulerZ: roll,
        leftEyeOpenProbability: leftEye,
        rightEyeOpenProbability: rightEye,
        isPaused: true,
        pauseReason: PauseReason.manual,
        scrollSpeedMultiplier: 0,
      );
    }

    if (headTurned) {
      _resumePending = false;
      return TrackingState(
        faceDetected: true,
        headEulerX: pitch,
        headEulerY: yaw,
        headEulerZ: roll,
        leftEyeOpenProbability: leftEye,
        rightEyeOpenProbability: rightEye,
        isPaused: true,
        pauseReason: PauseReason.headTurned,
        scrollSpeedMultiplier: 0,
      );
    }

    if (eyesClosed) {
      _resumePending = false;
      return TrackingState(
        faceDetected: true,
        headEulerX: pitch,
        headEulerY: yaw,
        headEulerZ: roll,
        leftEyeOpenProbability: leftEye,
        rightEyeOpenProbability: rightEye,
        isPaused: true,
        pauseReason: PauseReason.eyesClosed,
        scrollSpeedMultiplier: 0,
      );
    }

    final canResume = yaw.abs() < yawResumeThreshold && avgEye > eyeOpenThreshold;

    if (_state.isPaused && canResume) {
      if (!_resumePending) {
        _resumePending = true;
        _resumeAfter = DateTime.now().add(const Duration(milliseconds: 500));
      }
      if (DateTime.now().isBefore(_resumeAfter!)) {
        return TrackingState(
          faceDetected: true,
          headEulerX: pitch,
          headEulerY: yaw,
          headEulerZ: roll,
          leftEyeOpenProbability: leftEye,
          rightEyeOpenProbability: rightEye,
          isPaused: true,
          pauseReason: _state.pauseReason,
          scrollSpeedMultiplier: 0,
        );
      }
    } else if (!canResume) {
      _resumePending = false;
    }

    final multiplier = _scrollMultiplierFromPitch(pitch);

    return TrackingState(
      faceDetected: true,
      headEulerX: pitch,
      headEulerY: yaw,
      headEulerZ: roll,
      leftEyeOpenProbability: leftEye,
      rightEyeOpenProbability: rightEye,
      isPaused: false,
      pauseReason: PauseReason.none,
      scrollSpeedMultiplier: multiplier,
    );
  }

  double _scrollMultiplierFromPitch(double pitch) {
    // Looking down toward the screen often increases positive pitch on Android.
    if (pitch <= pitchBoostStart) return 1;
    final boost = ((pitch - pitchBoostStart) / (pitchBoostMax - pitchBoostStart))
        .clamp(0.0, 1.0);
    return 1 + boost * 0.45;
  }

  void setManualPause(bool paused) {
    _manualPause = paused;
    if (paused) {
      _resumePending = false;
      _state = _state.copyWith(
        isPaused: true,
        pauseReason: PauseReason.manual,
        scrollSpeedMultiplier: 0,
      );
    } else {
      _resumePending = false;
      _resumeAfter = null;
    }
  }

  Future<void> dispose() async {
    _isStreaming = false;
    if (_controller != null) {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
      await _controller!.dispose();
    }
    await _detector.close();
  }
}
