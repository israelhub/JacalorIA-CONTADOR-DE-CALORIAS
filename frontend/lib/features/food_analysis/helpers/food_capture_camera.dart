import 'package:camera/camera.dart';

/// Escolhe a camera para captura de refeicao.
///
/// Prefere a traseira wide: no iPhone, ultra-wide e telephoto costumam nao
/// ter LED, e [availableCameras] nao garante ordem.
CameraDescription selectFoodCaptureCamera(List<CameraDescription> cameras) {
  if (cameras.isEmpty) {
    throw StateError('Nenhuma câmera disponível neste dispositivo.');
  }

  final backCameras = cameras
      .where((camera) => camera.lensDirection == CameraLensDirection.back)
      .toList();
  if (backCameras.isEmpty) {
    return cameras.first;
  }

  backCameras.sort(
    (a, b) =>
        _lensPreference(a.lensType).compareTo(_lensPreference(b.lensType)),
  );
  return backCameras.first;
}

int _lensPreference(CameraLensType lensType) {
  switch (lensType) {
    case CameraLensType.wide:
      return 0;
    case CameraLensType.unknown:
      return 1;
    case CameraLensType.telephoto:
      return 2;
    case CameraLensType.ultraWide:
      return 3;
  }
}
