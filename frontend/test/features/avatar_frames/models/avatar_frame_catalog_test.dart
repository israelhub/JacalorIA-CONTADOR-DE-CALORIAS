import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/avatar_frames/models/avatar_frame_catalog.dart';

void main() {
  test('catalogo sempre inclui moldura padrao gratuita', () {
    expect(AvatarFrameCatalog.items.first.id, AvatarFrameCatalog.noneId);
    expect(AvatarFrameCatalog.items.first.isFree, isTrue);
    expect(AvatarFrameCatalog.purchasableItems, hasLength(7));
  });

  test('normaliza ids comprados vindos do perfil', () {
    final ids = AvatarFrameCatalog.purchasedIdsFromProfile({
      'purchasedAvatarFrameIds': ['cat_ears_soft', 42, '', 'unknown'],
    });

    expect(ids, {'cat_ears_soft'});
  });
}
