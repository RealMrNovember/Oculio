import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

/// Cross-device [CameraImage] → ML Kit [InputImage] conversion (Android).
///
/// Tries NV21 first (Camera2 / single-plane), then YUV_420_888 → NV21 rebuild.
InputImage? inputImageFromCameraImage(
  CameraImage image,
  CameraDescription camera,
  DeviceOrientation deviceOrientation,
) {
  if (!Platform.isAndroid) return null;

  final rotation = _rotationFromCamera(camera, deviceOrientation);
  if (rotation == null) return null;

  final nv21 = _toNv21Bytes(image);
  if (nv21 == null) return null;

  return InputImage.fromBytes(
    bytes: nv21,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: InputImageFormat.nv21,
      bytesPerRow: image.width,
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

  var rotationCompensation = orientations[orientation] ?? 0;

  if (camera.lensDirection == CameraLensDirection.front) {
    rotationCompensation =
        (camera.sensorOrientation + rotationCompensation) % 360;
  } else {
    rotationCompensation =
        (camera.sensorOrientation - rotationCompensation + 360) % 360;
  }

  return InputImageRotationValue.fromRawValue(rotationCompensation);
}

Uint8List? _toNv21Bytes(CameraImage image) {
  if (image.planes.isEmpty) return null;

  // Already NV21 (single plane) — common with Camera2 + ImageFormatGroup.nv21.
  if (image.planes.length == 1) {
    final expected = image.width * image.height * 3 ~/ 2;
    final bytes = image.planes.first.bytes;
    if (bytes.length >= expected) {
      return bytes.length == expected
          ? bytes
          : Uint8List.fromList(bytes.sublist(0, expected));
    }
  }

  if (image.planes.length != 3) return null;

  return _yuv420888ToNv21(image);
}

Uint8List _yuv420888ToNv21(CameraImage image) {
  final width = image.width;
  final height = image.height;
  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];

  final nv21 = Uint8List(width * height + (width * height ~/ 2));
  var offset = 0;

  for (var row = 0; row < height; row++) {
    final rowStart = row * yPlane.bytesPerRow;
    final copyLen = rowStart + width <= yPlane.bytes.length
        ? width
        : (yPlane.bytes.length - rowStart).clamp(0, width);
    if (copyLen > 0) {
      nv21.setRange(offset, offset + copyLen, yPlane.bytes, rowStart);
    }
    offset += width;
  }

  final uvPixelStride = uPlane.bytesPerPixel ?? 1;
  final vPixelStride = vPlane.bytesPerPixel ?? 1;
  final uvHeight = height ~/ 2;
  final uvWidth = width ~/ 2;

  for (var row = 0; row < uvHeight; row++) {
    for (var col = 0; col < uvWidth; col++) {
      final uIndex = row * uPlane.bytesPerRow + col * uvPixelStride;
      final vIndex = row * vPlane.bytesPerRow + col * vPixelStride;
      if (uIndex >= uPlane.bytes.length || vIndex >= vPlane.bytes.length) {
        continue;
      }
      nv21[offset++] = vPlane.bytes[vIndex];
      nv21[offset++] = uPlane.bytes[uIndex];
    }
  }

  return nv21;
}
