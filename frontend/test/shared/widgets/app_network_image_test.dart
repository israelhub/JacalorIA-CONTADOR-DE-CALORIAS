import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/shared/widgets/app_network_image.dart';

void main() {
  test('resolveAspectSafeMemCache nao define width e height juntos', () {
    final square = resolveAspectSafeMemCache(
      width: 72,
      height: 72,
      devicePixelRatio: 2,
    );
    expect(square.width, 144);
    expect(square.height, isNull);

    final landscape = resolveAspectSafeMemCache(
      width: 200,
      height: 100,
      devicePixelRatio: 1,
    );
    expect(landscape.width, 200);
    expect(landscape.height, isNull);

    final portrait = resolveAspectSafeMemCache(
      width: 100,
      height: 200,
      devicePixelRatio: 1,
    );
    expect(portrait.width, isNull);
    expect(portrait.height, 200);
  });

  testWidgets('cache de rede preserva proporcao sem forcar quadrado', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(devicePixelRatio: 2),
        child: MaterialApp(
          home: AppNetworkImage(
            url: 'https://example.com/meal.jpg',
            width: 72,
            height: 72,
          ),
        ),
      ),
    );

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.memCacheWidth, 144);
    expect(image.memCacheHeight, isNull);
    expect(image.maxWidthDiskCache, 144);
    expect(image.maxHeightDiskCache, isNull);
    expect(image.cacheManager, AppImageCacheManager.instance);
  });
}
