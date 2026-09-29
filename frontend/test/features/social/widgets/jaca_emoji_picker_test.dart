import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jacaloria/features/social/models/jaca_emoji_catalog.dart';
import 'package:jacaloria/features/social/widgets/jaca_emoji_picker.dart';

void main() {
  test('catalogo expoe os 10 emojis do Jaca', () {
    expect(JacaEmojiCatalog.items, hasLength(10));
    expect(JacaEmojiCatalog.byId('feliz')?.label, 'Feliz');
    expect(JacaEmojiCatalog.byId('forca')?.assetPath, contains('forca.png'));
    expect(JacaEmojiCatalog.byId('nao-existe'), isNull);
  });

  test('cinco figurinhas sao compraveis na loja', () {
    expect(JacaEmojiCatalog.paidIds, {
      'amor',
      'fogo',
      'festa',
      'sono',
      'forca',
    });
    expect(JacaEmojiCatalog.visibleItems(const <String>{}), hasLength(5));
    expect(
      JacaEmojiCatalog.visibleItems(const <String>{}).map((item) => item.id),
      ['feliz', 'triste', 'surpreso', 'fome', 'joinha'],
    );
    expect(JacaEmojiCatalog.visibleItems({'festa', 'amor'}), hasLength(7));
  });

  testWidgets('dispara o emoji tocado', (tester) async {
    JacaEmojiItem? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JacaEmojiPicker(onSelected: (emoji) => selected = emoji),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('jaca-emoji-feliz')));
    await tester.pump();

    expect(selected?.id, 'feliz');
    expect(selected?.label, 'Feliz');
  });

  testWidgets('esconde figurinhas pagas ate o usuario comprar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: JacaEmojiPicker(onSelected: _noop),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('jaca-emoji-feliz')), findsOneWidget);
    expect(find.byKey(const ValueKey('jaca-emoji-festa')), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JacaEmojiPicker(
            ownedIds: const {'festa'},
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('jaca-emoji-festa')), findsOneWidget);
  });
}

void _noop(JacaEmojiItem _) {}
