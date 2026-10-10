import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<Uint8List?> encodeImageBytesToJpegInBrowser(
  Uint8List bytes, {
  required int maxDimension,
  required int quality,
}) async {
  if (bytes.isEmpty) {
    return null;
  }

  final sourceBlob = web.Blob([bytes.toJS].toJS);
  final objectUrl = web.URL.createObjectURL(sourceBlob);

  try {
    final imageElement = await _loadImage(objectUrl);
    final width = imageElement.naturalWidth;
    final height = imageElement.naturalHeight;
    if (width <= 0 || height <= 0) {
      return null;
    }

    final longestSide = math.max(width, height);
    var targetWidth = width;
    var targetHeight = height;
    if (longestSide > maxDimension) {
      final scale = maxDimension / longestSide;
      targetWidth = math.max(1, (width * scale).round());
      targetHeight = math.max(1, (height * scale).round());
    }

    final canvas = web.HTMLCanvasElement()
      ..width = targetWidth
      ..height = targetHeight;
    final context = canvas.context2D;
    context.drawImage(
      imageElement,
      0,
      0,
      targetWidth.toDouble(),
      targetHeight.toDouble(),
    );

    final jpegBlob = await _canvasToJpegBlob(canvas, quality);
    if (jpegBlob.size <= 0) {
      return null;
    }

    final buffer = await jpegBlob.arrayBuffer().toDart;
    return Uint8List.fromList(buffer.toDart.asUint8List());
  } catch (_) {
    return null;
  } finally {
    web.URL.revokeObjectURL(objectUrl);
  }
}

Future<web.HTMLImageElement> _loadImage(String objectUrl) {
  final completer = Completer<web.HTMLImageElement>();
  final imageElement = web.HTMLImageElement()..src = objectUrl;

  late final StreamSubscription<web.Event> loadSub;
  late final StreamSubscription<web.Event> errorSub;

  void finish(void Function() action) {
    loadSub.cancel();
    errorSub.cancel();
    action();
  }

  loadSub = imageElement.onLoad.listen((_) {
    finish(() => completer.complete(imageElement));
  });
  errorSub = imageElement.onError.listen((_) {
    finish(
      () => completer.completeError(StateError('Falha ao carregar imagem.')),
    );
  });

  return completer.future;
}

Future<web.Blob> _canvasToJpegBlob(
  web.HTMLCanvasElement canvas,
  int quality,
) {
  final completer = Completer<web.Blob>();
  final clampedQuality = (quality.clamp(1, 100) / 100).toDouble();
  final web.BlobCallback callback = (web.Blob blob) {
    completer.complete(blob);
  }.toJS;

  canvas.toBlob(callback, 'image/jpeg', clampedQuality.toJS);
  return completer.future;
}
