import 'dart:math' as math;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Normalized eye height inside face box (0 = top, 1 = bottom of face).
double? eyeNormalizedYFromFace(Face face) {
  final left = face.landmarks[FaceLandmarkType.leftEye];
  final right = face.landmarks[FaceLandmarkType.rightEye];
  if (left == null || right == null) return null;

  final box = face.boundingBox;
  if (box.height <= 0) return null;

  final eyeY = (left.position.y + right.position.y) / 2.0;
  return ((eyeY - box.top) / box.height).clamp(0.0, 1.0);
}

/// Optional debug distance between eyes (stable when face rolls slightly).
double eyeSpanNormalized(Face face) {
  final left = face.landmarks[FaceLandmarkType.leftEye];
  final right = face.landmarks[FaceLandmarkType.rightEye];
  if (left == null || right == null) return 0;
  final box = face.boundingBox;
  if (box.width <= 0) return 0;
  return (right.position.x - left.position.x).abs() / box.width;
}

double toDegrees(double radians) => radians * 180 / math.pi;
