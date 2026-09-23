class JacaEmojiItem {
  const JacaEmojiItem({
    required this.id,
    required this.label,
    required this.assetPath,
    this.isPurchasable = false,
  });

  final String id;
  final String label;
  final String assetPath;
  final bool isPurchasable;
}

class JacaEmojiCatalog {
  JacaEmojiCatalog._();

  static const items = <JacaEmojiItem>[
    JacaEmojiItem(
      id: 'feliz',
      label: 'Feliz',
      assetPath: 'assets/images/jaca_emojis/feliz.png',
    ),
    JacaEmojiItem(
      id: 'amor',
      label: 'Amor',
      assetPath: 'assets/images/jaca_emojis/amor.png',
      isPurchasable: true,
    ),
    JacaEmojiItem(
      id: 'fogo',
      label: 'Fogo',
      assetPath: 'assets/images/jaca_emojis/fogo.png',
      isPurchasable: true,
    ),
    JacaEmojiItem(
      id: 'triste',
      label: 'Triste',
      assetPath: 'assets/images/jaca_emojis/triste.png',
    ),
    JacaEmojiItem(
      id: 'surpreso',
      label: 'Surpreso',
      assetPath: 'assets/images/jaca_emojis/surpreso.png',
    ),
    JacaEmojiItem(
      id: 'festa',
      label: 'Festa',
      assetPath: 'assets/images/jaca_emojis/festa.png',
      isPurchasable: true,
    ),
    JacaEmojiItem(
      id: 'fome',
      label: 'Fome',
      assetPath: 'assets/images/jaca_emojis/fome.png',
    ),
    JacaEmojiItem(
      id: 'joinha',
      label: 'Joinha',
      assetPath: 'assets/images/jaca_emojis/joinha.png',
    ),
    JacaEmojiItem(
      id: 'sono',
      label: 'Sono',
      assetPath: 'assets/images/jaca_emojis/sono.png',
      isPurchasable: true,
    ),
    JacaEmojiItem(
      id: 'forca',
      label: 'Força',
      assetPath: 'assets/images/jaca_emojis/forca.png',
      isPurchasable: true,
    ),
  ];

  static const ids = [
    'feliz',
    'amor',
    'fogo',
    'triste',
    'surpreso',
    'festa',
    'fome',
    'joinha',
    'sono',
    'forca',
  ];

  static const paidIds = {'amor', 'fogo', 'festa', 'sono', 'forca'};

  static JacaEmojiItem? byId(String? id) {
    final normalized = id?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    for (final item in items) {
      if (item.id == normalized) return item;
    }
    return null;
  }

  static bool isPurchasable(String id) => paidIds.contains(id);

  static bool isAvailable(String id, Set<String> purchasedIds) {
    return !isPurchasable(id) || purchasedIds.contains(id);
  }

  static List<JacaEmojiItem> visibleItems(Set<String> purchasedIds) {
    return items
        .where((item) => isAvailable(item.id, purchasedIds))
        .toList(growable: false);
  }

  static Set<String> purchasedIdsFromProfile(Map<String, dynamic>? profile) {
    final raw =
        profile?['purchasedJacaEmojiIds'] ??
        profile?['purchased_jaca_emoji_ids'];
    final values = raw is Iterable
        ? raw
        : raw is String
        ? raw.split(',')
        : const <Object?>[];

    return values
        .map((value) => value.toString().trim())
        .where((id) => id.isNotEmpty && isPurchasable(id))
        .toSet();
  }
}
