import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:jacaloria/features/food_analysis/helpers/image_optimizer.dart';

Uint8List _jpeg({required int width, required int height}) {
  final source = img.Image(width: width, height: height);
  img.fill(source, color: img.ColorRgb8(200, 120, 40));
  return Uint8List.fromList(img.encodeJpg(source, quality: 95));
}

void main() {
  group('resizeAndEncodeForAnalysis', () {
    test('preserva proporcao paisagem ao reduzir', () {
      final output = img.decodeImage(
        resizeAndEncodeForAnalysis(_jpeg(width: 4000, height: 2000)),
      )!;

      expect(output.width, maxAnalysisImageDimension);
      expect(output.height, 960);
      expect(output.width / output.height, closeTo(2, 0.01));
    });

    test('preserva proporcao retrato ao reduzir', () {
      final output = img.decodeImage(
        resizeAndEncodeForAnalysis(_jpeg(width: 1200, height: 4000)),
      )!;

      expect(output.height, maxAnalysisImageDimension);
      expect(output.width, 576);
      expect(output.height / output.width, closeTo(4000 / 1200, 0.01));
    });

    test('nao achata imagem que ja cabe no limite', () {
      final output = img.decodeImage(
        resizeAndEncodeForAnalysis(_jpeg(width: 800, height: 1200)),
      )!;

      expect(output.width, 800);
      expect(output.height, 1200);
    });
  });
}
