import 'package:flutter_test/flutter_test.dart';
import 'package:jacaloria/features/avatar_frames/models/avatar_background_catalog.dart';

void main() {
  test('catalogo inclui sky com asset mapeado', () {
    expect(AvatarBackgroundCatalog.byId('sky')?.assetPath,
        'assets/images/avatar_backgrounds/sky.png');
  });

  test('assetPathForId retorna null para fundo desconhecido', () {
    expect(AvatarBackgroundCatalog.assetPathForId('mango_sky'), isNull);
  });

  test('normaliza ids comprados vindos do perfil', () {
    final ids = AvatarBackgroundCatalog.purchasedBackgroundIdsFromProfile({
      'purchasedAvatarBackgroundIds': ['sky', 'unknown', ''],
    });

    expect(ids, {'sky'});
  });
}
