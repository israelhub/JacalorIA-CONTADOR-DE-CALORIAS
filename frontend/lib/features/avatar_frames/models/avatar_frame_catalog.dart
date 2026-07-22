class AvatarFrameItem {
  const AvatarFrameItem({
    required this.id,
    required this.name,
    required this.description,
    required this.assetPath,
  });

  final String id;
  final String name;
  final String description;
  final String? assetPath;

  bool get isFree => id == AvatarFrameCatalog.noneId;
}

enum StoreCategory { blockers, frames, backgrounds }

enum StoreItemType { blocker, frame, background }

enum StoreBlockerAction { inventory, restore }

class StoreCatalogItem {
  const StoreCatalogItem({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.priceGold,
    this.quantityOwned = 0,
    this.blockerAction = StoreBlockerAction.inventory,
    this.restoreAvailable = false,
    this.missingDaysUntilToday = 0,
  });

  final String id;
  final StoreItemType type;
  final String name;
  final String description;
  final int priceGold;
  final int quantityOwned;
  final StoreBlockerAction blockerAction;
  final bool restoreAvailable;
  final int missingDaysUntilToday;

  bool get isConsumable => type == StoreItemType.blocker;
  bool get isStreakRestore =>
      blockerAction == StoreBlockerAction.restore || id == 'streak_restore';
  bool get isInventoryBlocker => isConsumable && !isStreakRestore;
}

class StoreCatalogData {
  const StoreCatalogData({
    required this.frames,
    required this.backgrounds,
    required this.blockers,
    this.blockerRecovery = const BlockerRecoveryInfo(),
  });

  final List<StoreCatalogItem> frames;
  final List<StoreCatalogItem> backgrounds;
  final List<StoreCatalogItem> blockers;
  final BlockerRecoveryInfo blockerRecovery;

  static StoreCatalogData fromJson(Map<String, dynamic> json) {
    final store =
        (json['store'] as Map<String, dynamic>?) ??
        (json['catalog'] as Map<String, dynamic>?) ??
        json;

    var frames = _parseStoreItems(
      (store['avatarFrames'] as List?) ?? (store['frames'] as List?),
      type: StoreItemType.frame,
    );
    var backgrounds = _parseStoreItems(
      (store['avatarBackgrounds'] as List?) ?? (store['backgrounds'] as List?),
      type: StoreItemType.background,
    );
    var blockers = _parseStoreItems(
      (store['blockers'] as List?) ?? (store['profileBlockers'] as List?),
      type: StoreItemType.blocker,
    );

    if ((frames.isEmpty || backgrounds.isEmpty || blockers.isEmpty) &&
        store['categories'] is List) {
      final categories = (store['categories'] as List)
          .whereType<Map>()
          .map((value) => value.cast<String, dynamic>())
          .toList(growable: false);

      for (final category in categories) {
        final id = category['id']?.toString().trim().toLowerCase() ?? '';
        final rawItems = category['items'] as List<dynamic>?;
        if (rawItems == null) {
          continue;
        }

        if (id == 'avatar_frames' && frames.isEmpty) {
          frames = _parseStoreItems(rawItems, type: StoreItemType.frame);
        } else if (id == 'avatar_backgrounds' && backgrounds.isEmpty) {
          backgrounds = _parseStoreItems(
            rawItems,
            type: StoreItemType.background,
          );
        } else if (id == 'offensive_blockers' && blockers.isEmpty) {
          blockers = _parseStoreItems(rawItems, type: StoreItemType.blocker);
        }
      }
    }

    return StoreCatalogData(
      frames: frames,
      backgrounds: backgrounds,
      blockers: blockers,
      blockerRecovery: BlockerRecoveryInfo.fromJson(
        (json['blockerRecovery'] as Map<String, dynamic>?) ??
            (store['blockerRecovery'] as Map<String, dynamic>?) ??
            const <String, dynamic>{},
      ),
    );
  }
}

class BlockerRecoveryInfo {
  const BlockerRecoveryInfo({
    this.missingDaysUntilToday = 0,
    this.requiredBlockersTotal = 0,
    this.inventoryAvailable = 0,
    this.requiredPurchaseQuantity = 0,
    this.requiredPurchaseCostGold = 0,
    this.canAffordRecoveryPurchase = true,
  });

  final int missingDaysUntilToday;
  final int requiredBlockersTotal;
  final int inventoryAvailable;
  final int requiredPurchaseQuantity;
  final int requiredPurchaseCostGold;
  final bool canAffordRecoveryPurchase;

  factory BlockerRecoveryInfo.fromJson(Map<String, dynamic> json) {
    return BlockerRecoveryInfo(
      missingDaysUntilToday: AvatarFrameCatalog._asInt(
        json['missingDaysUntilToday'] ?? json['missing_days_until_today'],
      ),
      requiredBlockersTotal: AvatarFrameCatalog._asInt(
        json['requiredBlockersTotal'] ?? json['required_blockers_total'],
      ),
      inventoryAvailable: AvatarFrameCatalog._asInt(
        json['inventoryAvailable'] ?? json['inventory_available'],
      ),
      requiredPurchaseQuantity: AvatarFrameCatalog._asInt(
        json['requiredPurchaseQuantity'] ?? json['required_purchase_quantity'],
      ),
      requiredPurchaseCostGold: AvatarFrameCatalog._asInt(
        json['requiredPurchaseCostGold'] ?? json['required_purchase_cost_gold'],
      ),
      canAffordRecoveryPurchase:
          json['canAffordRecoveryPurchase'] == true ||
          json['can_afford_recovery_purchase'] == true,
    );
  }
}

class AvatarFrameCatalog {
  const AvatarFrameCatalog._();

  static const String noneId = 'none';

  static const List<AvatarFrameItem> items = [
    AvatarFrameItem(
      id: noneId,
      name: 'Sem moldura',
      description: 'Foto limpa, sem borda equipada.',
      assetPath: null,
    ),
    AvatarFrameItem(
      id: 'emerald_guard',
      name: 'Guarda Esmeralda',
      description: 'Folhas de armadura, ouro e cristais verdes.',
      assetPath: 'assets/images/avatar_frames/emerald_guard.png',
    ),
    AvatarFrameItem(
      id: 'crystal_champion',
      name: 'Campeao Cristalino',
      description: 'Cristais violetas com laterais douradas.',
      assetPath: 'assets/images/avatar_frames/crystal_champion.png',
    ),
    AvatarFrameItem(
      id: 'cosmic_blossom',
      name: 'Floracao Cosmica',
      description: 'Galhos magenta, estrelas e joias lunares.',
      assetPath: 'assets/images/avatar_frames/cosmic_blossom.png',
    ),
    AvatarFrameItem(
      id: 'cat_ears_soft',
      name: 'Orelhas de Gato',
      description: 'Moldura suave com orelhinhas felinas.',
      assetPath: 'assets/images/avatar_frames/cat_ears.png',
    ),
    AvatarFrameItem(
      id: 'gator_tail_fin',
      name: 'Cauda de Jacare',
      description: 'Moldura suave inspirada no estilo do Jaca.',
      assetPath: 'assets/images/avatar_frames/jaca.png',
    ),
    AvatarFrameItem(
      id: 'fox_autumn_tail',
      name: 'Raposa de Outono',
      description: 'Orelhas e cauda felpuda em tons de outono.',
      assetPath: 'assets/images/avatar_frames/fox_tail.png',
    ),
    AvatarFrameItem(
      id: 'panda_bamboo',
      name: 'Panda Bamboo',
      description: 'Orelhas e patinhas de panda com bambu fresco.',
      assetPath: 'assets/images/avatar_frames/panda.png',
    ),
    AvatarFrameItem(
      id: 'fire_streak',
      name: 'Chama da Sequencia',
      description: 'Anel em brasa com chamas da ofensiva.',
      assetPath: 'assets/images/avatar_frames/fire_streak.png',
    ),
    AvatarFrameItem(
      id: 'fruit_ring',
      name: 'Coroa de Frutas',
      description: 'Frutas e vegetais frescos ao redor do perfil.',
      assetPath: 'assets/images/avatar_frames/fruit_ring.png',
    ),
    AvatarFrameItem(
      id: 'royal_gold',
      name: 'Ouro Real',
      description: 'Anel dourado com coroa, gemas e moedas.',
      assetPath: 'assets/images/avatar_frames/royal_gold.png',
    ),
  ];

  static List<AvatarFrameItem> get purchasableItems =>
      items.where((item) => !item.isFree).toList(growable: false);

  static AvatarFrameItem? byId(String? id) {
    if (id == null || id.trim().isEmpty) {
      return null;
    }

    for (final item in items) {
      if (item.id == id.trim()) {
        return item;
      }
    }

    return null;
  }

  static String equippedIdFromProfile(Map<String, dynamic>? profile) {
    final raw =
        profile?['equippedAvatarFrameId'] ??
        profile?['equipped_avatar_frame_id'];
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty || byId(value) == null) {
      return noneId;
    }

    return value;
  }

  static Set<String> purchasedIdsFromProfile(Map<String, dynamic>? profile) {
    final raw =
        profile?['purchasedAvatarFrameIds'] ??
        profile?['purchased_avatar_frame_ids'];
    final values = raw is Iterable
        ? raw
        : raw is String
        ? raw.split(',')
        : const <Object?>[];

    return values
        .map((value) => value.toString().trim())
        .where((id) => id.isNotEmpty && byId(id) != null && id != noneId)
        .toSet();
  }

  static bool isOwned(String frameId, Set<String> purchasedFrameIds) {
    return frameId == noneId || purchasedFrameIds.contains(frameId);
  }

  static Map<String, int> blockerInventoryFromProfile(
    Map<String, dynamic>? profile,
  ) {
    final directCount = _asInt(
      profile?['offensiveBlockerInventoryCount'] ??
          profile?['offensive_blocker_inventory_count'],
    );
    final directBlockerId =
        profile?['equippedOffensiveBlockerId']?.toString().trim() ??
        profile?['equipped_offensive_blocker_id']?.toString().trim() ??
        'offensive_guard';
    if (directCount > 0 && directBlockerId.isNotEmpty) {
      return <String, int>{directBlockerId: directCount};
    }

    final raw =
        profile?['blockers'] ??
        profile?['profileBlockers'] ??
        profile?['blockersInventory'] ??
        profile?['inventoryBlockers'];

    if (raw is Map) {
      final map = <String, int>{};
      raw.forEach((key, value) {
        final id = key.toString().trim();
        if (id.isEmpty) {
          return;
        }
        map[id] = _asInt(value);
      });
      return map;
    }

    if (raw is Iterable) {
      final map = <String, int>{};
      for (final item in raw) {
        if (item is Map) {
          final id = item['id']?.toString().trim() ?? '';
          if (id.isEmpty) {
            continue;
          }
          final quantity = _asInt(
            item['quantity'] ?? item['count'] ?? item['amount'],
          );
          map[id] = quantity;
        } else {
          final id = item.toString().trim();
          if (id.isEmpty) {
            continue;
          }
          map[id] = (map[id] ?? 0) + 1;
        }
      }
      return map;
    }

    return const <String, int>{};
  }

  static int _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}

List<StoreCatalogItem> _parseStoreItems(
  List<dynamic>? rawItems, {
  required StoreItemType type,
}) {
  if (rawItems == null) {
    return const <StoreCatalogItem>[];
  }

  return rawItems
      .whereType<Map>()
      .map((raw) {
        final map = raw.cast<String, dynamic>();
        final id =
            map['id']?.toString() ??
            map['key']?.toString() ??
            map['code']?.toString() ??
            '';
        final name = map['name']?.toString() ?? map['title']?.toString() ?? '';
        final description = map['description']?.toString() ?? '';
        final price = AvatarFrameCatalog._asInt(
          map['priceGold'] ?? map['price'] ?? map['goldCost'],
        );
        final storeAction = map['storeAction']?.toString().trim().toLowerCase() ??
            map['store_action']?.toString().trim().toLowerCase();
        final idTrimmed = id.trim();
        final blockerAction = storeAction == 'streak_restore' ||
                idTrimmed == 'streak_restore'
            ? StoreBlockerAction.restore
            : StoreBlockerAction.inventory;

        return StoreCatalogItem(
          id: idTrimmed,
          type: type,
          name: name,
          description: description,
          priceGold: price,
          quantityOwned: AvatarFrameCatalog._asInt(
            map['quantityOwned'] ?? map['quantity'] ?? map['count'],
          ),
          blockerAction: type == StoreItemType.blocker
              ? blockerAction
              : StoreBlockerAction.inventory,
          restoreAvailable:
              map['restoreAvailable'] == true ||
              map['restore_available'] == true,
          missingDaysUntilToday: AvatarFrameCatalog._asInt(
            map['missingDaysUntilToday'] ?? map['missing_days_until_today'],
          ),
        );
      })
      .where((item) => item.id.isNotEmpty)
      .toList(growable: false);
}
