import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/avatar_frames/models/avatar_frame_catalog.dart';

void main() {
  test('catalogo sempre inclui moldura padrao gratuita', () {
    expect(AvatarFrameCatalog.items.first.id, AvatarFrameCatalog.noneId);
    expect(AvatarFrameCatalog.items.first.priceGold, 0);
    expect(AvatarFrameCatalog.purchasableItems, hasLength(3));
  });

  test('normaliza ids comprados vindos do perfil', () {
    final ids = AvatarFrameCatalog.purchasedIdsFromProfile({
      'purchasedAvatarFrameIds': ['emerald_guard', 42, '', 'unknown'],
    });

    expect(ids, {'emerald_guard'});
  });

  test('calcula saldo descontando molduras ja compradas', () {
    final balance = AvatarFrameCatalog.availableGold(
      earnedGold: 320,
      purchasedFrameIds: {'emerald_guard', 'crystal_champion'},
    );

    expect(balance, 20);
  });

  test('nao permite comprar moldura sem saldo suficiente', () {
    expect(
      AvatarFrameCatalog.canPurchase(
        AvatarFrameCatalog.byId('cosmic_blossom')!,
        availableGold: 80,
        purchasedFrameIds: const <String>{},
      ),
      isFalse,
    );
  });
}
