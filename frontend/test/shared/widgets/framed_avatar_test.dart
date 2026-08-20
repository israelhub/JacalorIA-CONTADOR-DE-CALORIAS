import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/shared/widgets/framed_avatar.dart';

void main() {
  testWidgets('mantem tamanho fixo dentro de Row', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              FramedAvatar(
                size: 44,
                avatarUrl: 'https://example.com/avatar.jpg',
                fallbackText: 'J',
              ),
            ],
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(FramedAvatar));
    expect(size.width, 44);
    expect(size.height, 44);
  });

  testWidgets('mantem tamanho fixo com moldura', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              FramedAvatar(
                size: 44,
                avatarUrl: 'https://example.com/avatar.jpg',
                frameId: 'fire_streak',
                fallbackText: 'J',
              ),
            ],
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(FramedAvatar));
    expect(size.width, 44);
    expect(size.height, 44);
  });
}
