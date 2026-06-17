import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:oculio_mobile/models/tracking_state.dart';
import 'package:oculio_mobile/services/gaze_scroll_controller.dart';
import 'package:oculio_mobile/utils/camera_image_converter.dart';
import 'package:oculio_mobile/utils/face_geometry.dart';
import 'package:permission_handler/permission_handler.dart';

typedef TrackingCallback = void Function(TrackingState state);

/// Face pipeline + gaze-proxy scroll (pitch dynamics, not continuous WPM).
class FaceTrackingService {
  FaceTrackingService();

  static const double yawPauseThreshold = 35;
  static const double yawResumeThreshold = 25;
  static const double eyeClosedThreshold = 0.25;
  static const double eyeOpenThreshold = 0.5;

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.08,
    ),
  );

  final GazeScrollController _gazeScroll = GazeScrollController();

  CameraController? _controller;
  bool _isStreaming = false;
  bool _manualPause = false;
  bool _resumePending = false;
  DateTime? _resumeAfter;
  int _frameSkip = 0;
  int _convertFailStreak = 0;
  int _framesProcessed = 0;
  double _lineHeightPx = 32;
  double _scrollSensitivity = 1.0;

  TrackingState _state = const TrackingState(
    isPaused: true,
    pipelineStatus: 'initializing',
  );

  CameraController? get controller => _controller;
  TrackingState get state => _state;

  void configureScroll({
    required double lineHeightPx,
    double sensitivity = 1.0,
  }) {
    _lineHeightPx = lineHeightPx;
    _scrollSensitivity = sensitivity;
  }

  Future<bool> initialize() async {
    final cameraStatus = await Permission.camera.request();
    if (!cameraStatus.isGranted) {
      _state = _state.copyWith(pipelineStatus: 'camera_denied');
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
      imageFormatGroup:
          Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    _gazeScroll.reset();
    _state = _state.copyWith(
      pipelineStatus: 'camera_ready',
      readingMode: ReadingMode.eyeAssist,
      isPaused: true,
      pauseReason: PauseReason.noFace,
    );
    return true;
  }

  Future<void> start(TrackingCallback onUpdate) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isStreaming) return;

    _isStreaming = true;
    _gazeScroll.reset();
    _state = _state.copyWith(pipelineStatus: 'streaming');
    onUpdate(_state);

    await _controller!.startImageStream((image) async {
      if (!_isStreaming) return;

      _frameSkip = (_frameSkip + 1) % 2;
      if (_frameSkip != 0) return;
      if (_state.isProcessing) return;

      _framesProcessed++;
      _state = _state.copyWith(
        isProcessing: true,
        framesProcessed: _framesProcessed,
      );

      try {
        final inputImage = inputImageFromCameraImage(
          image,
          _controller!.description,
          _controller!.value.deviceOrientation,
        );

        if (inputImage == null) {
          _convertFailStreak++;
          _state = _state.copyWith(
            faceDetected: false,
            isPaused: true,
            pauseReason: PauseReason.noFace,
            scrollVelocityPxPerSec: 0,
            gazeZone: GazeZone.holding,
            isProcessing: false,
            pipelineStatus:
                'convert_fail x$_convertFailStreak p=${image.planes.length}',
            facesInFrame: 0,
            readingMode: ReadingMode.wpmFallback,
          );
          onUpdate(_state);
          return;
        }

        _convertFailStreak = 0;
        final faces = await _detector.processImage(inputImage);

        if (faces.isEmpty) {
          _state = _state.copyWith(
            faceDetected: false,
            isPaused: true,
            pauseReason: PauseReason.noFace,
            scrollVelocityPxPerSec: 0,
            gazeZone: GazeZone.holding,
            isProcessing: false,
            pipelineStatus: 'no_face',
            facesInFrame: 0,
            readingMode: ReadingMode.eyeAssist,
          );
          _resumePending = false;
          onUpdate(_state);
          return;
        }

        final face = faces.first;
        final next = _evaluateFace(face, faces.length);
        _state = next;
        onUpdate(_state);
      } catch (error, stack) {
        debugPrint('[FaceTracking] $error\n$stack');
        _state = _state.copyWith(
          isProcessing: false,
          pipelineStatus: 'ml_error',
          scrollVelocityPxPerSec: 0,
        );
        onUpdate(_state);
      }
    });
  }

  TrackingState _evaluateFace(Face face, int faceCount) {
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
        scrollVelocityPxPerSec: 0,
        gazeZone: GazeZone.holding,
        readingMode: ReadingMode.manual,
        pipelineStatus: 'manual_pause',
        facesInFrame: faceCount,
        framesProcessed: _framesProcessed,
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
        scrollVelocityPxPerSec: 0,
        gazeZone: GazeZone.holding,
        readingMode: ReadingMode.eyeAssist,
        pipelineStatus: 'paused_look_away',
        facesInFrame: faceCount,
        framesProcessed: _framesProcessed,
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
        scrollVelocityPxPerSec: 0,
        gazeZone: GazeZone.holding,
        readingMode: ReadingMode.eyeAssist,
        pipelineStatus: 'paused_eyes_closed',
        facesInFrame: faceCount,
        framesProcessed: _framesProcessed,
      );
    }

    final canResume =
        yaw.abs() < yawResumeThreshold && avgEye > eyeOpenThreshold;

    if (_state.isPaused && canResume) {
      if (!_resumePending) {
        _resumePending = true;
        _resumeAfter = DateTime.now().add(const Duration(milliseconds: 350));
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
          scrollVelocityPxPerSec: 0,
          gazeZone: GazeZone.holding,
          readingMode: ReadingMode.eyeAssist,
          pipelineStatus: 'resuming',
          facesInFrame: faceCount,
          framesProcessed: _framesProcessed,
          isProcessing: false,
        );
      }
    } else if (!canResume) {
      _resumePending = false;
    }

    final gaze = _gazeScroll.compute(
      pitch: pitch,
      eyeNormalizedY: eyeNormalizedYFromFace(face),
      lineHeightPx: _lineHeightPx,
    );

    final velocity = gaze.velocityPxPerSec * _scrollSensitivity;

    return TrackingState(
      faceDetected: true,
      headEulerX: pitch,
      headEulerY: yaw,
      headEulerZ: roll,
      leftEyeOpenProbability: leftEye,
      rightEyeOpenProbability: rightEye,
      isPaused: false,
      pauseReason: PauseReason.none,
      scrollVelocityPxPerSec: velocity,
      gazeZone: gaze.zone,
      isProcessing: false,
      readingMode: ReadingMode.eyeAssist,
      pipelineStatus: gaze.zone.name,
      facesInFrame: faceCount,
      framesProcessed: _framesProcessed,
      gazeScore: gaze.gazeScore,
      eyeNormalizedY: gaze.eyeNormalizedY,
    );
  }

  void setManualPause(bool paused) {
    _manualPause = paused;
    if (paused) {
      _resumePending = false;
      _state = _state.copyWith(
        isPaused: true,
        pauseReason: PauseReason.manual,
        scrollVelocityPxPerSec: 0,
        readingMode: ReadingMode.manual,
        pipelineStatus: 'manual_pause',
      );
    } else {
      _resumePending = false;
      _resumeAfter = null;
      _gazeScroll.reset();
      _state = _state.copyWith(
        isPaused: false,
        readingMode: ReadingMode.eyeAssist,
        pipelineStatus: 'manual_resume',
      );
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
