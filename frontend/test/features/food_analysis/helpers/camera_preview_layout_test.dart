import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/food_analysis/helpers/camera_preview_layout.dart';

CameraValue _value({
  required double width,
  required double height,
  DeviceOrientation orientation = DeviceOrientation.portraitUp,
}) {
  return CameraValue(
    isInitialized: true,
    isRecordingVideo: false,
    isTakingPicture: false,
    isStreamingImages: false,
    isRecordingPaused: false,
    flashMode: FlashMode.off,
    exposureMode: ExposureMode.auto,
    focusMode: FocusMode.auto,
    exposurePointSupported: false,
    focusPointSupported: false,
    deviceOrientation: orientation,
    description: const CameraDescription(
      name: 'test',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    ),
    previewSize: Size(width, height),
  );
}

void main() {
  group('cameraPreviewAspectRatio', () {
    test('inverte em retrato', () {
      expect(
        cameraPreviewAspectRatio(_value(width: 1920, height: 1080)),
        closeTo(1080 / 1920, 0.001),
      );
    });

    test('mantem em paisagem', () {
      expect(
        cameraPreviewAspectRatio(
          _value(
            width: 1920,
            height: 1080,
            orientation: DeviceOrientation.landscapeLeft,
          ),
        ),
        closeTo(1920 / 1080, 0.001),
      );
    });
  });

  group('cameraCoverSize', () {
    test('expande na largura quando o preview e mais largo que o container', () {
      final size = cameraCoverSize(
        maxWidth: 360,
        maxHeight: 640,
        previewAspect: 0.75,
      );
      expect(size.height, 640);
      expect(size.width, closeTo(480, 0.1));
    });

    test('expande na altura quando o preview e mais estreito que o container', () {
      final size = cameraCoverSize(
        maxWidth: 360,
        maxHeight: 640,
        previewAspect: 0.5,
      );
      expect(size.width, 360);
      expect(size.height, closeTo(720, 0.1));
    });
  });
}
