import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

/// Mesma regra de [CameraPreview]: em retrato inverte width/height do sensor.
double cameraPreviewAspectRatio(CameraValue value) {
  final ratio = value.aspectRatio;
  if (!ratio.isFinite || ratio <= 0) {
    return 1;
  }

  final orientation = value.previewPauseOrientation ??
      value.lockedCaptureOrientation ??
      value.deviceOrientation;
  final isLandscape =
      orientation == DeviceOrientation.landscapeLeft ||
      orientation == DeviceOrientation.landscapeRight;
  return isLandscape ? ratio : 1 / ratio;
}

Size cameraCoverSize({
  required double maxWidth,
  required double maxHeight,
  required double previewAspect,
}) {
  final aspect = (!previewAspect.isFinite || previewAspect <= 0)
      ? 1.0
      : previewAspect;

  var width = maxWidth;
  var height = width / aspect;
  if (height < maxHeight) {
    height = maxHeight;
    width = height * aspect;
  }
  return Size(width, height);
}
