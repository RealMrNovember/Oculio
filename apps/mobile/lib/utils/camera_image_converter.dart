import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

/// Converts a [CameraImage] stream frame into ML Kit [InputImage] (Android).
InputImage? inputImageFromCameraImage(
  CameraImage image,
  CameraDescription camera,
  DeviceOrientation deviceOrientation,
) {
  if (!Platform.isAndroid) return null;

  final rotation = _rotationFromCamera(camera, deviceOrientation);
  if (rotation == null) return null;

  final format = InputImageFormatValue.fromRawValue(image.format.raw);
  if (format == null) return null;

  if (image.planes.isEmpty) return null;

  final bytes = _concatenatePlanes(image.planes);
  if (bytes == null) return null;

  return InputImage.fromBytes(
    bytes: bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    ),
  );
}

InputImageRotation? _rotationFromCamera(
  CameraDescription camera,
  DeviceOrientation orientation,
) {
  const orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  var rotationCompensation = orientations[orientation];
  if (rotationCompensation == null) return null;

  if (camera.lensDirection == CameraLensDirection.front) {
    rotationCompensation =
        (camera.sensorOrientation + rotationCompensation) % 360;
  } else {
    rotationCompensation =
        (camera.sensorOrientation - rotationCompensation + 360) % 360;
  }

  return InputImageRotationValue.fromRawValue(rotationCompensation);
}

Uint8List? _concatenatePlanes(List<Plane> planes) {
  final buffer = WriteBuffer();
  for (final plane in planes) {
    buffer.putUint8List(plane.bytes);
  }
  return buffer.done().buffer.asUint8List();
}
