import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class OptimizedImage {
  const OptimizedImage({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

const int maxAnalysisImageDimension = 1920;
const int analysisJpegQuality = 90;

Future<OptimizedImage> optimizeForAnalysis(Uint8List original) async {
  try {
    final bytes = await compute(resizeAndEncodeForAnalysis, original);
    return OptimizedImage(bytes: bytes, mimeType: 'image/jpeg');
  } catch (_) {
    return OptimizedImage(bytes: original, mimeType: 'image/jpeg');
  }
}

Uint8List resizeAndEncodeForAnalysis(Uint8List input) {
  final decoded = img.decodeImage(input);
  if (decoded == null) {
    return input;
  }

  var image = img.bakeOrientation(decoded);
  final longestSide = math.max(image.width, image.height);

  if (longestSide > maxAnalysisImageDimension) {
    final scale = maxAnalysisImageDimension / longestSide;
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

  return Uint8List.fromList(
    img.encodeJpg(image, quality: analysisJpegQuality),
  );
}
