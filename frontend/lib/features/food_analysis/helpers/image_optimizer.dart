import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'browser_jpeg_encoder.dart';

class OptimizedImage {
  const OptimizedImage({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

const int maxAnalysisImageDimension = 1920;
const int analysisJpegQuality = 90;
const int maxAvatarImageDimension = 512;
const int avatarJpegQuality = 85;

Future<OptimizedImage> optimizeForAvatar(Uint8List original) {
  return _optimize(
    original,
    maxDimension: maxAvatarImageDimension,
    quality: avatarJpegQuality,
    resize: resizeAndEncodeForAvatar,
  );
}

Future<OptimizedImage> optimizeForAnalysis(Uint8List original) {
  return _optimize(
    original,
    maxDimension: maxAnalysisImageDimension,
    quality: analysisJpegQuality,
    resize: resizeAndEncodeForAnalysis,
  );
}

Future<OptimizedImage> _optimize(
  Uint8List original, {
  required int maxDimension,
  required int quality,
  required Uint8List Function(Uint8List input) resize,
}) async {
  final fromBrowser = await encodeImageBytesToJpegInBrowser(
    original,
    maxDimension: maxDimension,
    quality: quality,
  );
  if (fromBrowser != null && fromBrowser.isNotEmpty) {
    return OptimizedImage(bytes: _copyBytes(fromBrowser), mimeType: 'image/jpeg');
  }

  try {
    final bytes = kIsWeb ? resize(original) : await compute(resize, original);
    return OptimizedImage(bytes: _copyBytes(bytes), mimeType: 'image/jpeg');
  } catch (_) {
    final copy = _copyBytes(original);
    if (!kIsWeb || _isCommonRaster(copy)) {
      return OptimizedImage(bytes: copy, mimeType: _guessMimeType(copy));
    }
    throw StateError(
      'Não foi possível processar esta imagem. Tente JPG ou PNG.',
    );
  }
}

Uint8List resizeAndEncodeForAvatar(Uint8List input) {
  return _resizeAndEncodeJpeg(
    input,
    maxDimension: maxAvatarImageDimension,
    quality: avatarJpegQuality,
  );
}

Uint8List resizeAndEncodeForAnalysis(Uint8List input) {
  return _resizeAndEncodeJpeg(
    input,
    maxDimension: maxAnalysisImageDimension,
    quality: analysisJpegQuality,
  );
}

Uint8List _resizeAndEncodeJpeg(
  Uint8List input, {
  required int maxDimension,
  required int quality,
}) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(input);
  } catch (_) {
    decoded = null;
  }
  if (decoded == null) {
    throw StateError('Formato de imagem não suportado');
  }

  var image = img.bakeOrientation(decoded);
  final longestSide = math.max(image.width, image.height);

  if (longestSide > maxDimension) {
    final scale = maxDimension / longestSide;
    final targetWidth = math.max(1, (image.width * scale).round());
    final targetHeight = math.max(1, (image.height * scale).round());
    image = img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
      maintainAspect: true,
      interpolation: img.Interpolation.linear,
    );
  }

  return Uint8List.fromList(img.encodeJpg(image, quality: quality));
}

Uint8List _copyBytes(Uint8List input) {
  return Uint8List.fromList(input);
}

bool _isCommonRaster(Uint8List bytes) {
  return _looksLikeJpeg(bytes) || _looksLikePng(bytes) || _looksLikeWebp(bytes);
}

String _guessMimeType(Uint8List bytes) {
  if (_looksLikePng(bytes)) {
    return 'image/png';
  }
  if (_looksLikeWebp(bytes)) {
    return 'image/webp';
  }
  return 'image/jpeg';
}

bool _looksLikeJpeg(Uint8List bytes) {
  return bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF;
}

bool _looksLikePng(Uint8List bytes) {
  return bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47;
}

bool _looksLikeWebp(Uint8List bytes) {
  return bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50;
}
