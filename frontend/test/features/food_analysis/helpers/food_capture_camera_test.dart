import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/food_analysis/helpers/food_capture_camera.dart';

CameraDescription _cam({
  required String name,
  required CameraLensDirection direction,
  CameraLensType lensType = CameraLensType.unknown,
}) {
  return CameraDescription(
    name: name,
    lensDirection: direction,
    sensorOrientation: 90,
    lensType: lensType,
  );
}

void main() {
  group('selectFoodCaptureCamera', () {
    test('prefere traseira wide quando ultra-wide vem primeiro', () {
      final selected = selectFoodCaptureCamera([
        _cam(
          name: 'ultra',
          direction: CameraLensDirection.back,
          lensType: CameraLensType.ultraWide,
        ),
        _cam(
          name: 'wide',
          direction: CameraLensDirection.back,
          lensType: CameraLensType.wide,
        ),
        _cam(name: 'front', direction: CameraLensDirection.front),
      ]);

      expect(selected.name, 'wide');
      expect(selected.lensType, CameraLensType.wide);
    });

    test('usa frente quando nao ha traseira', () {
      final selected = selectFoodCaptureCamera([
        _cam(name: 'front', direction: CameraLensDirection.front),
      ]);

      expect(selected.name, 'front');
    });

    test('lanca quando lista esta vazia', () {
      expect(
        () => selectFoodCaptureCamera(const []),
        throwsA(isA<StateError>()),
      );
    });
  });
}
