class AvatarBackgroundItem {
  const AvatarBackgroundItem({
    required this.id,
    required this.name,
    required this.description,
    required this.assetPath,
  });

  final String id;
  final String name;
  final String description;
  final String assetPath;
}

class AvatarBackgroundCatalog {
  const AvatarBackgroundCatalog._();

  static const List<AvatarBackgroundItem> items = [
    AvatarBackgroundItem(
      id: 'sunset_orbit',
      name: 'Sunset Orbit',
      description: 'Por do sol com orbitas suaves.',
      assetPath: 'assets/images/avatar_backgrounds/sunset_orbit.png',
    ),
    AvatarBackgroundItem(
      id: 'jungle_neon',
      name: 'Jungle Neon',
      description: 'Selva vibrante com brilho neon.',
      assetPath: 'assets/images/avatar_backgrounds/jungle_neon.png',
    ),
    AvatarBackgroundItem(
      id: 'aurora_grid',
      name: 'Aurora Grid',
      description: 'Aurora boreal com grade futurista.',
      assetPath: 'assets/images/avatar_backgrounds/aurora_grid.png',
    ),
    AvatarBackgroundItem(
      id: 'sky',
      name: 'Sky',
      description: 'Ceú aberto com tons azuis.',
      assetPath: 'assets/images/avatar_backgrounds/sky.png',
    ),
    AvatarBackgroundItem(
      id: 'pantano',
      name: 'Pantano',
      description: 'Atmosfera verde e misteriosa.',
      assetPath: 'assets/images/avatar_backgrounds/pantano.png',
    ),
  ];

  static AvatarBackgroundItem? byId(String? id) {
    if (id == null || id.trim().isEmpty) {
      return null;
    }

    final normalized = id.trim();
    for (final item in items) {
      if (item.id == normalized) {
        return item;
      }
    }

    return null;
  }

  static String? assetPathForId(String? id) => byId(id)?.assetPath;

  static String equippedBackgroundIdFromProfile(Map<String, dynamic>? profile) {
    final raw =
        profile?['equippedAvatarBackgroundId'] ??
        profile?['equipped_avatar_background_id'];
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty || byId(value) == null) {
      return '';
    }

    return value;
  }

  static Set<String> purchasedBackgroundIdsFromProfile(
    Map<String, dynamic>? profile,
  ) {
    final raw =
        profile?['purchasedAvatarBackgroundIds'] ??
        profile?['purchased_avatar_background_ids'];
    final values = raw is Iterable
        ? raw
        : raw is String
        ? raw.split(',')
        : const <Object?>[];

    return values
        .map((value) => value.toString().trim())
        .where((id) => id.isNotEmpty && byId(id) != null)
        .toSet();
  }
}
