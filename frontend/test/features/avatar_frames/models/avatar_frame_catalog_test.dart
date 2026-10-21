import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/avatar_frames/models/avatar_frame_catalog.dart';

void main() {
  test('catalogo sempre inclui moldura padrao gratuita', () {
    expect(AvatarFrameCatalog.items.first.id, AvatarFrameCatalog.noneId);
    expect(AvatarFrameCatalog.items.first.isFree, isTrue);
    expect(
      AvatarFrameCatalog.purchasableItems.length,
      AvatarFrameCatalog.items.length - 1,
    );
    expect(
      AvatarFrameCatalog.byId('tutorial_star_ring')?.assetPath,
      'assets/images/avatar_frames/tutorial_star_ring.png',
    );
  });

  test('normaliza ids comprados vindos do perfil', () {
    final ids = AvatarFrameCatalog.purchasedIdsFromProfile({
      'purchasedAvatarFrameIds': ['cat_ears_soft', 42, '', 'unknown'],
    });

    expect(ids, {'cat_ears_soft'});
  });
}
