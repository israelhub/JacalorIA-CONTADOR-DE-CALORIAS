import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/avatar_profile_preview.dart';
import '../../../shared/widgets/frame_silhouette_icon.dart';
import '../../../shared/widgets/framed_avatar.dart';
import '../../auth/service/auth_service.dart';
import '../../home/widgets/home_shell_layout.dart';
import '../../missions/services/missions_service.dart';
import '../../social/models/jaca_emoji_catalog.dart';
import '../models/avatar_background_catalog.dart';
import '../models/avatar_frame_catalog.dart';

class AvatarFrameStorePage extends StatefulWidget {
  const AvatarFrameStorePage({
    super.key,
    required this.initialGoldBalance,
    this.initialGoldLifetimeEarned = 0,
    this.initialGoldLifetimeSpent = 0,
    required this.profile,
    this.authService,
  });

  final int initialGoldBalance;
  final int initialGoldLifetimeEarned;
  final int initialGoldLifetimeSpent;
  final Map<String, dynamic> profile;
  final AuthService? authService;

  @override
  State<AvatarFrameStorePage> createState() => _AvatarFrameStorePageState();
}

class _AvatarFrameStorePageState extends State<AvatarFrameStorePage> {
  late Set<String> _purchasedFrameIds;
  late Set<String> _purchasedBackgroundIds;
  late Set<String> _purchasedStickerIds;
  late Map<String, int> _blockerInventory;
  late String _equippedFrameId;
  late String _equippedBackgroundId;
  late String _previewFrameId;
  late String _previewBackgroundId;
  late int _goldBalance;
  late Map<String, dynamic> _profileSnapshot;
  StoreCatalogData _catalog = const StoreCatalogData(
    frames: <StoreCatalogItem>[],
    backgrounds: <StoreCatalogItem>[],
    blockers: <StoreCatalogItem>[],
  );
  StoreCategory _selectedCategory = StoreCategory.blockers;
  final Set<StoreCategory> _visitedCategories = <StoreCategory>{
    StoreCategory.blockers,
  };
  bool _isLoadingCatalog = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  AuthService get _authService => widget.authService ?? AuthService();

  MissionsService get _missionsService => const MissionsService();

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackScreen('avatar_store');
    _profileSnapshot = Map<String, dynamic>.from(widget.profile);
    _purchasedFrameIds = AvatarFrameCatalog.purchasedIdsFromProfile(
      _profileSnapshot,
    );
    _equippedFrameId = AvatarFrameCatalog.equippedIdFromProfile(
      _profileSnapshot,
    );
    _purchasedBackgroundIds =
        AvatarBackgroundCatalog.purchasedBackgroundIdsFromProfile(_profileSnapshot);
    _purchasedStickerIds = JacaEmojiCatalog.purchasedIdsFromProfile(
      _profileSnapshot,
    );
    _equippedBackgroundId = AvatarBackgroundCatalog.equippedBackgroundIdFromProfile(
      _profileSnapshot,
    );
    _previewFrameId = _equippedFrameId;
    _previewBackgroundId = _equippedBackgroundId;
    _blockerInventory = AvatarFrameCatalog.blockerInventoryFromProfile(
      _profileSnapshot,
    );
    _goldBalance = widget.initialGoldBalance;

    // Stale-while-revalidate: pinta o catálogo do cache na hora e revalida
    // em segundo plano, sem spinner de tela cheia a cada abertura.
    final cached = MissionsService.cachedStoreCatalog;
    if (cached != null) {
      _applyCatalogResponse(cached);
      _isLoadingCatalog = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _precacheCatalogAssets();
      });
    }
    _loadCatalog(silent: cached != null);
  }

  void _applyCatalogResponse(Map<String, dynamic> response) {
    final profile = response['profile'] is Map<String, dynamic>
        ? response['profile'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final summary = response['summary'] is Map<String, dynamic>
        ? response['summary'] as Map<String, dynamic>
        : const <String, dynamic>{};

    if (profile.isNotEmpty) {
      _profileSnapshot.addAll(profile);
    }

    _catalog = StoreCatalogData.fromJson(response);
    _purchasedFrameIds = AvatarFrameCatalog.purchasedIdsFromProfile(
      _profileSnapshot,
    );
    _equippedFrameId = AvatarFrameCatalog.equippedIdFromProfile(
      _profileSnapshot,
    );
    _purchasedBackgroundIds =
        AvatarBackgroundCatalog.purchasedBackgroundIdsFromProfile(
          _profileSnapshot,
        );
    _purchasedStickerIds = JacaEmojiCatalog.purchasedIdsFromProfile(
      _profileSnapshot,
    );
    _equippedBackgroundId =
        AvatarBackgroundCatalog.equippedBackgroundIdFromProfile(
          _profileSnapshot,
        );
    _blockerInventory = AvatarFrameCatalog.blockerInventoryFromProfile(
      _profileSnapshot,
    );
    for (final blocker in _catalog.blockers) {
      if (blocker.isInventoryBlocker && blocker.quantityOwned > 0) {
        _blockerInventory[blocker.id] = blocker.quantityOwned;
      }
    }
    _goldBalance = _toInt(summary['gold'], _goldBalance);
  }

  Future<void> _loadCatalog({bool silent = false}) async {
    try {
      final response = await _missionsService.fetchStoreCatalog();
      if (!mounted) {
        return;
      }
      setState(() {
        _applyCatalogResponse(response);
        _isLoadingCatalog = false;
      });
      _precacheCatalogAssets();
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (silent) {
        // Revalidação em segundo plano falhou; mantém o conteúdo atual.
        return;
      }
      setState(() {
        _catalog = StoreCatalogData.fromJson(const <String, dynamic>{});
        _isLoadingCatalog = false;
      });
      _showToast(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  /// Mantém molduras/fundos decodificados no ImageCache do Flutter (crítico no
  /// web, onde trocar de categoria remonta o grid e redecodifica PNGs grandes).
  void _precacheCatalogAssets() {
    if (!mounted) {
      return;
    }

    final providers = <ImageProvider<Object>>[];

    for (final item in _catalog.frames) {
      final path = AvatarFrameCatalog.byId(item.id)?.assetPath;
      if (path != null && path.isNotEmpty) {
        providers.add(AssetImage(path));
      }
    }

    for (final item in _catalog.backgrounds) {
      final path = AvatarBackgroundCatalog.assetPathForId(item.id);
      if (path != null && path.isNotEmpty) {
        providers.add(AssetImage(path));
      }
    }

    for (final item in _catalog.stickers) {
      final path = JacaEmojiCatalog.byId(item.id)?.assetPath;
      if (path != null && path.isNotEmpty) {
        providers.add(AssetImage(path));
      }
    }

    final avatarUrl =
        _profileSnapshot['avatarUrl'] as String? ??
        _profileSnapshot['avatar_url'] as String?;
    if (avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        avatarUrl.startsWith('http')) {
      providers.add(CachedNetworkImageProvider(avatarUrl));
    }

    for (final provider in providers) {
      unawaited(() async {
        try {
          await precacheImage(provider, context);
        } catch (_) {}
      }());
    }
  }

  List<StoreCatalogItem> _itemsFor(StoreCategory category) {
    late final List<StoreCatalogItem> items;

    switch (category) {
      case StoreCategory.blockers:
        items = _catalog.blockers;
        break;
      case StoreCategory.frames:
        items = _catalog.frames;
        break;
      case StoreCategory.backgrounds:
        items = _catalog.backgrounds;
        break;
      case StoreCategory.stickers:
        items = _catalog.stickers;
        break;
    }

    final owned = <StoreCatalogItem>[];
    final locked = <StoreCatalogItem>[];
    for (final item in items) {
      if (_isOwned(item)) {
        owned.add(item);
      } else {
        locked.add(item);
      }
    }
    return [...owned, ...locked];
  }

  bool _isOwned(StoreCatalogItem item) {
    switch (item.type) {
      case StoreItemType.frame:
        return _purchasedFrameIds.contains(item.id);
      case StoreItemType.background:
        return _purchasedBackgroundIds.contains(item.id);
      case StoreItemType.sticker:
        return _purchasedStickerIds.contains(item.id);
      case StoreItemType.blocker:
        return (_blockerInventory[item.id] ?? 0) > 0;
    }
  }

  bool _isEquipped(StoreCatalogItem item) {
    switch (item.type) {
      case StoreItemType.frame:
        return _equippedFrameId == item.id;
      case StoreItemType.background:
        return _equippedBackgroundId == item.id;
      case StoreItemType.sticker:
      case StoreItemType.blocker:
        return false;
    }
  }

  int get _totalBlockerInventory {
    final fromMap = _blockerInventory.values.fold<int>(0, (sum, value) => sum + value);
    if (fromMap > 0) {
      return fromMap;
    }
    return _toInt(
      _profileSnapshot['offensiveBlockerInventoryCount'] ??
          _profileSnapshot['offensive_blocker_inventory_count'],
      0,
    );
  }

  Future<void> _buyOrEquip(StoreCatalogItem item) async {
    if (_isSaving) {
      return;
    }

    if (item.isCheckInExclusive && !_isOwned(item)) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop('go_to_missions');
      return;
    }

    final isOwned = _isOwned(item);
    final needsPurchase = item.isInventoryBlocker || !isOwned;
    if (needsPurchase) {
      if (_goldBalance < item.priceGold) {
        await _showInsufficientFundsDialog(item.priceGold);
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      late final Map<String, dynamic> response;
      late final String successMessage;

      switch (item.type) {
        case StoreItemType.frame:
          response = await _missionsService.purchaseAvatarFrame(item.id);
          successMessage = isOwned
              ? 'Moldura equipada.'
              : 'Moldura comprada e equipada.';
          break;
        case StoreItemType.background:
          response = await _missionsService.purchaseAvatarBackground(item.id);
          successMessage = isOwned
              ? 'Fundo equipado.'
              : 'Fundo comprado e equipado.';
          break;
        case StoreItemType.sticker:
          response = await _missionsService.purchaseJacaEmoji(item.id);
          successMessage = isOwned
              ? 'Figurinha já desbloqueada.'
              : 'Figurinha desbloqueada.';
          break;
        case StoreItemType.blocker:
          response = await _missionsService.purchaseBlocker(
            blockerId: item.id,
            quantity: 1,
          );
          successMessage = 'Bloqueador comprado.';
          break;
      }

      _applyResponseState(response);
      // A resposta da compra já traz perfil/saldo atualizados; o catálogo
      // revalida em segundo plano sem travar o botão.
      AuthService.invalidateProfileCache();
      unawaited(_loadCatalog(silent: true));
      _hasChanges = true;

      if (!mounted) {
        return;
      }
      _showToast(successMessage);
    } catch (error) {
      if (mounted) {
        _showToast(
          error.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showInsufficientFundsDialog(int priceGold) async {
    if (!mounted) {
      return;
    }

    final missingGold =
        priceGold > _goldBalance ? priceGold - _goldBalance : 0;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AppModal(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ouro insuficiente',
                style: AppTextStyles.missionsSectionTitle.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Você precisa de mais ouro para comprar este item. '
                'Complete missões para ganhar recompensas.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.missionsGoldPill,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.performanceCardBorder),
                ),
                child: Column(
                  children: [
                    _InsufficientGoldRow(
                      label: 'Seu saldo',
                      value: _goldBalance,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _InsufficientGoldRow(
                      label: 'Preço do item',
                      value: priceGold,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Divider(
                        height: 1,
                        color: AppColors.performanceCardBorder,
                      ),
                    ),
                    _InsufficientGoldRow(
                      label: 'Faltam',
                      value: missingGold,
                      emphasize: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Entendi',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onTileTap(StoreCatalogItem item) async {
    if (!_isOwned(item) ||
        item.isInventoryBlocker ||
        item.type == StoreItemType.sticker) {
      _previewItem(item);
      return;
    }
    _equipOwnedItem(item);
  }

  void _equipOwnedItem(StoreCatalogItem item) {
    if (item.type == StoreItemType.frame) {
      final nextId = _equippedFrameId == item.id
          ? AvatarFrameCatalog.noneId
          : item.id;
      setState(() {
        _equippedFrameId = nextId;
        _previewFrameId = nextId;
        _profileSnapshot['equippedAvatarFrameId'] = nextId;
      });
      _hasChanges = true;
      unawaited(_persistEquippedCosmetic(
        field: 'equippedAvatarFrameId',
        value: nextId,
      ));
      return;
    }

    if (item.type == StoreItemType.background) {
      final nextId = _equippedBackgroundId == item.id
          ? AvatarFrameCatalog.noneId
          : item.id;
      setState(() {
        _equippedBackgroundId = nextId;
        _previewBackgroundId = nextId;
        _profileSnapshot['equippedAvatarBackgroundId'] = nextId;
      });
      _hasChanges = true;
      unawaited(_persistEquippedCosmetic(
        field: 'equippedAvatarBackgroundId',
        value: nextId,
      ));
    }
  }

  Future<void> _persistEquippedCosmetic({
    required String field,
    required String value,
  }) async {
    try {
      await _authService.updateProfile(<String, dynamic>{field: value});
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showToast(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _confirmPurchase(StoreCatalogItem item) async {
    if (_isSaving) {
      return;
    }
    if (item.isCheckInExclusive && !_isOwned(item)) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop('go_to_missions');
      return;
    }
    if (!item.isInventoryBlocker && _isOwned(item)) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AppModal(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Deseja comprar esse item?',
                textAlign: TextAlign.center,
                style: AppTextStyles.missionsSectionTitle.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 140,
                width: double.infinity,
                child: Center(
                  child: _StoreItemPreview(
                    item: item,
                    avatarUrl: _profileSnapshot['avatarUrl'] as String? ??
                        _profileSnapshot['avatar_url'] as String?,
                    name: _profileSnapshot['name']?.toString(),
                  ),
                ),
              ),
              if (item.isInventoryBlocker) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.brand900Variant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${item.priceGold}',
                    style: AppTextStyles.captionStrong.copyWith(
                      color: AppColors.brand900Variant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const AppSvgIcon.gold(size: 18),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancelar',
                      variant: AppButtonVariant.outline,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'Comprar',
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      await _buyOrEquip(item);
    }
  }

  void _applyResponseState(Map<String, dynamic> response) {
    final profile = response['profile'] is Map<String, dynamic>
        ? response['profile'] as Map<String, dynamic>
        : <String, dynamic>{};
    final summary = response['summary'] is Map<String, dynamic>
        ? response['summary'] as Map<String, dynamic>
        : <String, dynamic>{};

    if (profile.isNotEmpty) {
      _profileSnapshot.addAll(profile);
    }

    if (response['inventory'] is Map<String, dynamic>) {
      _profileSnapshot['blockers'] = response['inventory'];
    }
    final blockerCount = _toInt(
      profile['offensiveBlockerInventoryCount'] ??
          profile['offensive_blocker_inventory_count'],
      -1,
    );
    final blockerId =
        profile['equippedOffensiveBlockerId']?.toString().trim() ??
        profile['equipped_offensive_blocker_id']?.toString().trim() ??
        'offensive_guard';
    if (blockerCount >= 0 && blockerId.isNotEmpty) {
      _profileSnapshot['blockers'] = <String, int>{blockerId: blockerCount};
    }

    setState(() {
      _purchasedFrameIds = AvatarFrameCatalog.purchasedIdsFromProfile(
        _profileSnapshot,
      );
      _equippedFrameId = AvatarFrameCatalog.equippedIdFromProfile(
        _profileSnapshot,
      );
      _purchasedBackgroundIds =
          AvatarBackgroundCatalog.purchasedBackgroundIdsFromProfile(
            _profileSnapshot,
          );
      _purchasedStickerIds = JacaEmojiCatalog.purchasedIdsFromProfile(
        _profileSnapshot,
      );
      _equippedBackgroundId =
          AvatarBackgroundCatalog.equippedBackgroundIdFromProfile(_profileSnapshot);
      _previewFrameId = _equippedFrameId;
      _previewBackgroundId = _equippedBackgroundId;
      _blockerInventory = AvatarFrameCatalog.blockerInventoryFromProfile(
        _profileSnapshot,
      );
      _goldBalance = _toInt(summary['gold'], _goldBalance);
    });
  }

  void _previewItem(StoreCatalogItem item) {
    switch (item.type) {
      case StoreItemType.frame:
        setState(() {
          _previewFrameId = item.id;
        });
        return;
      case StoreItemType.background:
        setState(() {
          _previewBackgroundId = item.id;
        });
        return;
      case StoreItemType.sticker:
      case StoreItemType.blocker:
        return;
    }
  }

  int _toInt(Object? value, int fallback) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  void _showToast(String message, {bool isError = false}) {
    AppToast.show(
      context,
      message: message,
      isError: isError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl =
        _profileSnapshot['avatarUrl'] as String? ??
        _profileSnapshot['avatar_url'] as String?;
    final name = _profileSnapshot['name']?.toString();

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(_hasChanges);
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: AppColors.surface,
          titleSpacing: AppSpacing.lg,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Loja',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _GoldPill(value: _goldBalance.toString()),
              const SizedBox(width: AppSpacing.xs),
              _BlockerPill(value: _totalBlockerInventory.toString()),
            ],
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: homeShellNestedFillPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AvatarProfilePreview(
                  avatarUrl: avatarUrl,
                  frameId: _previewFrameId,
                  backgroundId: _previewBackgroundId,
                  name: name ?? 'Perfil',
                ),
                const SizedBox(height: AppSpacing.lg),
                _StoreCategorySwitcher(
                  selected: _selectedCategory,
                  onSelected: (category) {
                    setState(() {
                      _selectedCategory = category;
                      _visitedCategories.add(category);
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.action500,
                    onRefresh: _loadCatalog,
                    child: _isLoadingCatalog
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: AppSpacing.xl),
                              Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.action500,
                                ),
                              ),
                            ],
                          )
                        // IndexedStack mantém catálogos já visitados montados:
                        // trocar de aba não descarta tiles nem reanima/redecodifica.
                        : IndexedStack(
                            index: _selectedCategory.index,
                            sizing: StackFit.expand,
                            children: [
                              for (final category in StoreCategory.values)
                                _visitedCategories.contains(category)
                                    ? _StoreCategoryGrid(
                                        key: ValueKey(
                                          'store-grid-$category',
                                        ),
                                        category: category,
                                        items: _itemsFor(category),
                                        avatarUrl: avatarUrl,
                                        name: name,
                                        blockerInventory: _blockerInventory,
                                        isOwned: _isOwned,
                                        isEquipped: _isEquipped,
                                        isSaving: _isSaving,
                                        onTileTap: _onTileTap,
                                        onBuy: _confirmPurchase,
                                      )
                                    : const SizedBox.expand(),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreCategoryGrid extends StatelessWidget {
  const _StoreCategoryGrid({
    super.key,
    required this.category,
    required this.items,
    required this.avatarUrl,
    required this.name,
    required this.blockerInventory,
    required this.isOwned,
    required this.isEquipped,
    required this.isSaving,
    required this.onTileTap,
    required this.onBuy,
  });

  final StoreCategory category;
  final List<StoreCatalogItem> items;
  final String? avatarUrl;
  final String? name;
  final Map<String, int> blockerInventory;
  final bool Function(StoreCatalogItem item) isOwned;
  final bool Function(StoreCatalogItem item) isEquipped;
  final bool isSaving;
  final ValueChanged<StoreCatalogItem> onTileTap;
  final ValueChanged<StoreCatalogItem> onBuy;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text(
              'Sem itens disponíveis nesta categoria.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 720 ? 3 : 2;
        // Sem o nome do item, o rodape (meta + botao) e mais curto. Fundos
        // (banner largo) ficam mais compactos; molduras/bloqueadores ganham
        // altura pra o preview nao esmagar o botao em telas estreitas.
        final childAspectRatio =
            category == StoreCategory.backgrounds ? 1.35 : 1.12;
        return GridView.builder(
          // Evita reconstruir tiles fora da viewport ao voltar pra categoria.
          addAutomaticKeepAlives: true,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _StoreTileEntrance(
              key: ValueKey('store-tile-${category.name}-${item.id}'),
              index: index,
              child: _StoreTile(
                item: item,
                avatarUrl: avatarUrl,
                name: name,
                blockerQuantity: blockerInventory[item.id] ?? 0,
                blockerQuantityFallback: item.quantityOwned,
                isOwned: isOwned(item),
                isEquipped: isEquipped(item),
                isSaving: isSaving,
                onTileTap: () => onTileTap(item),
                onBuy: () => onBuy(item),
              ),
            );
          },
        );
      },
    );
  }
}

class _StoreCategorySwitcher extends StatelessWidget {
  const _StoreCategorySwitcher({
    required this.selected,
    required this.onSelected,
  });

  static const _indicatorWidth = 22.0;
  static const _indicatorHeight = 3.0;

  final StoreCategory selected;
  final ValueChanged<StoreCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabCount = StoreCategory.values.length;
        final tabWidth = constraints.maxWidth / tabCount;
        final left =
            selected.index * tabWidth + (tabWidth - _indicatorWidth) / 2;

        return SizedBox(
          height: 46,
          child: Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _CategoryButton(
                      label: 'Bloqueadores',
                      iconBuilder: (color) => Icon(
                        Icons.shield_outlined,
                        size: 26,
                        color: color,
                      ),
                      isSelected: selected == StoreCategory.blockers,
                      onTap: () => onSelected(StoreCategory.blockers),
                    ),
                  ),
                  Expanded(
                    child: _CategoryButton(
                      label: 'Molduras',
                      iconBuilder: (color) => SizedBox(
                        width: 26,
                        height: 26,
                        child: Center(
                          child: FrameSilhouetteIcon(
                            size: 22,
                            color: color,
                          ),
                        ),
                      ),
                      isSelected: selected == StoreCategory.frames,
                      onTap: () => onSelected(StoreCategory.frames),
                    ),
                  ),
                  Expanded(
                    child: _CategoryButton(
                      label: 'Fundos',
                      iconBuilder: (color) => Icon(
                        Icons.landscape_outlined,
                        size: 26,
                        color: color,
                      ),
                      isSelected: selected == StoreCategory.backgrounds,
                      onTap: () => onSelected(StoreCategory.backgrounds),
                    ),
                  ),
                  Expanded(
                    child: _CategoryButton(
                      label: 'Figurinhas',
                      iconBuilder: (color) => AppSvgIcon.sticker(
                        size: 26,
                        color: color,
                      ),
                      isSelected: selected == StoreCategory.stickers,
                      onTap: () => onSelected(StoreCategory.stickers),
                    ),
                  ),
                ],
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: left,
                bottom: 2,
                width: _indicatorWidth,
                height: _indicatorHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.brand900Variant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.iconBuilder,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Widget Function(Color color) iconBuilder;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: _PressableCategoryButton(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, 10),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) {
              final iconColor = Color.lerp(
                AppColors.textSecondary,
                AppColors.brand900Variant,
                t,
              )!;
              return iconBuilder(iconColor);
            },
          ),
        ),
      ),
    );
  }
}

class _PressableCategoryButton extends StatefulWidget {
  const _PressableCategoryButton({
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressableCategoryButton> createState() => _PressableCategoryButtonState();
}

class _PressableCategoryButtonState extends State<_PressableCategoryButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }

    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: Duration(milliseconds: _isPressed ? 90 : 280),
        curve: _isPressed ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

class _InsufficientGoldRow extends StatelessWidget {
  const _InsufficientGoldRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final int value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final valueColor = emphasize
        ? AppColors.missionsRewardGold
        : AppColors.brand900Variant;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMuted,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$value',
          style: AppTextStyles.captionStrong.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        const AppSvgIcon.gold(size: 18),
      ],
    );
  }
}

class _GoldPill extends StatelessWidget {
  const _GoldPill({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.missionsGoldPill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.performanceCardBorder),
      ),
      child: Row(
        children: <Widget>[
          const AppSvgIcon.gold(size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.missionsPillValue.copyWith(
              color: AppColors.brand900Variant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockerPill extends StatelessWidget {
  const _BlockerPill({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.performanceCardBorder),
      ),
      child: Row(
        children: <Widget>[
          const AppSvgIcon.blocker(size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.missionsPillValue.copyWith(
              color: AppColors.brand900Variant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({
    required this.item,
    required this.avatarUrl,
    required this.name,
    required this.blockerQuantity,
    required this.blockerQuantityFallback,
    required this.isOwned,
    required this.isEquipped,
    required this.isSaving,
    required this.onTileTap,
    required this.onBuy,
  });

  final StoreCatalogItem item;
  final String? avatarUrl;
  final String? name;
  final int blockerQuantity;
  final int blockerQuantityFallback;
  final bool isOwned;
  final bool isEquipped;
  final bool isSaving;
  final VoidCallback onTileTap;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final effectiveBlockerQuantity = blockerQuantity > 0
        ? blockerQuantity
        : blockerQuantityFallback;
    final isCheckInExclusive = item.isCheckInExclusive && !isOwned;
    final showPrice = item.isInventoryBlocker || (!isOwned && !isCheckInExclusive);
    final showChip = showPrice || isCheckInExclusive;

    return GestureDetector(
      onTap: onTileTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isEquipped
                ? AppColors.action500
                : AppColors.performanceCardBorder,
            width: isEquipped ? 2 : 1.5,
          ),
          boxShadow: AppShadows.sm,
        ),
        clipBehavior: Clip.none,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: _StoreItemPreview(
                  item: item,
                  avatarUrl: avatarUrl,
                  name: name,
                ),
              ),
            ),
            if (showChip)
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isSaving ? null : onBuy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isCheckInExclusive
                          ? AppColors.missionsXpPill
                          : AppColors.missionsGoldPill,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: AppShadows.sm,
                    ),
                    child: isCheckInExclusive
                        ? Text(
                            'Check-in',
                            style: AppTextStyles.missionsPillValue.copyWith(
                              color: AppColors.brand900Variant,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (item.isInventoryBlocker &&
                                  effectiveBlockerQuantity > 0) ...[
                                Text(
                                  'x$effectiveBlockerQuantity',
                                  style: AppTextStyles.missionsPillValue.copyWith(
                                    color: AppColors.action500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                '${item.priceGold}',
                                style: AppTextStyles.missionsPillValue.copyWith(
                                  color: AppColors.brand900Variant,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const AppSvgIcon.gold(size: 18),
                            ],
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StoreTileEntrance extends StatelessWidget {
  const _StoreTileEntrance({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + (index * 20)),
      curve: Curves.easeOutCubic,
      builder: (context, value, childWidget) {
        final eased = Curves.easeOut.transform(value);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 14),
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }
}

class _StoreItemPreview extends StatelessWidget {
  const _StoreItemPreview({
    required this.item,
    required this.avatarUrl,
    required this.name,
  });

  static const double _preferredSize = 140;

  final StoreCatalogItem item;
  final String? avatarUrl;
  final String? name;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        switch (item.type) {
          case StoreItemType.frame:
            final size = _resolveSquareSize(constraints);
            return FramedAvatar(
              size: size,
              avatarUrl: avatarUrl,
              frameId: item.id,
              fallbackText: name,
            );
          case StoreItemType.background:
            // Mesma proporcao do banner do perfil (nao quadrado).
            final width = _resolveBannerWidth(constraints);
            final height = width / AvatarProfilePreview.bannerAspectRatio;
            final assetPath = AvatarBackgroundCatalog.assetPathForId(item.id);
            if (assetPath != null) {
              // Decodifica só no tamanho exibido; os PNGs de fundo são grandes.
              final cacheWidth =
                  (width * MediaQuery.devicePixelRatioOf(context)).round();
              return ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.asset(
                  assetPath,
                  width: width,
                  height: height,
                  cacheWidth: cacheWidth > 0 ? cacheWidth : null,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.medium,
                ),
              );
            }
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                gradient: const LinearGradient(
                  colors: [AppColors.missionsXpPill, AppColors.brand300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: AppColors.performanceCardBorder),
              ),
              child: Icon(
                Icons.landscape_rounded,
                size: math.max(24.0, height * 0.45),
                color: AppColors.brand900Variant,
              ),
            );
          case StoreItemType.blocker:
            final size = _resolveSquareSize(constraints);
            final iconSize = math.max(24.0, size * 0.37);
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceAlt,
                border: Border.all(color: AppColors.performanceCardBorder),
              ),
              child: AppSvgIcon.blocker(
                size: iconSize,
              ),
            );
          case StoreItemType.sticker:
            final size = _resolveSquareSize(constraints);
            final path = JacaEmojiCatalog.byId(item.id)?.assetPath;
            if (path != null) {
              return Image.asset(
                path,
                width: size,
                height: size,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              );
            }
            return SizedBox(
              width: size,
              height: size,
              child: AppSvgIcon.sticker(
                size: math.max(24.0, size * 0.45),
                color: AppColors.brand900Variant,
              ),
            );
        }
      },
    );
  }

  double _resolveSquareSize(BoxConstraints constraints) {
    var resolved = _preferredSize;
    if (constraints.maxWidth.isFinite) {
      resolved = math.min(resolved, constraints.maxWidth);
    }
    if (constraints.maxHeight.isFinite) {
      resolved = math.min(resolved, constraints.maxHeight);
    }
    return math.max(0.0, resolved);
  }

  double _resolveBannerWidth(BoxConstraints constraints) {
    if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
      return constraints.maxWidth;
    }
    return _preferredSize;
  }
}
