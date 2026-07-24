import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/avatar_profile_preview.dart';
import '../../../shared/widgets/frame_silhouette_icon.dart';
import '../../../shared/widgets/framed_avatar.dart';
import '../../auth/service/auth_service.dart';
import '../../missions/services/missions_service.dart';
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
  bool _showOwnedOnly = false;
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
    _equippedBackgroundId = AvatarBackgroundCatalog.equippedBackgroundIdFromProfile(
      _profileSnapshot,
    );
    _previewFrameId = _equippedFrameId;
    _previewBackgroundId = _equippedBackgroundId;
    _blockerInventory = AvatarFrameCatalog.blockerInventoryFromProfile(
      _profileSnapshot,
    );
    _goldBalance = widget.initialGoldBalance;
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final response = await _missionsService.fetchStoreCatalog();
      if (!mounted) {
        return;
      }
      final profile = response['profile'] is Map<String, dynamic>
          ? response['profile'] as Map<String, dynamic>
          : const <String, dynamic>{};
      final summary = response['summary'] is Map<String, dynamic>
          ? response['summary'] as Map<String, dynamic>
          : const <String, dynamic>{};

      if (profile.isNotEmpty) {
        _profileSnapshot.addAll(profile);
      }

      setState(() {
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
        _isLoadingCatalog = false;
      });
    } catch (error) {
      if (!mounted) {
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

  List<StoreCatalogItem> _selectedItems() {
    late final List<StoreCatalogItem> items;

    switch (_selectedCategory) {
      case StoreCategory.blockers:
        items = _catalog.blockers;
        break;
      case StoreCategory.frames:
        items = _catalog.frames;
        break;
      case StoreCategory.backgrounds:
        items = _catalog.backgrounds;
        break;
    }

    if (!_showOwnedOnly) {
      return items;
    }

    return items.where(_isOwned).toList(growable: false);
  }

  bool _isOwned(StoreCatalogItem item) {
    switch (item.type) {
      case StoreItemType.frame:
        return _purchasedFrameIds.contains(item.id);
      case StoreItemType.background:
        return _purchasedBackgroundIds.contains(item.id);
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
      case StoreItemType.blocker:
        return false;
    }
  }

  bool _canPurchase(StoreCatalogItem item) {
    if (item.isInventoryBlocker) {
      return _goldBalance >= item.priceGold;
    }
    if (_isOwned(item)) {
      return true;
    }
    return _goldBalance >= item.priceGold;
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
        case StoreItemType.blocker:
          response = await _missionsService.purchaseBlocker(
            blockerId: item.id,
            quantity: 1,
          );
          successMessage = 'Bloqueador comprado.';
          break;
      }

      _applyResponseState(response);
      await _loadCatalog();
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

  Future<void> _toggleOwnedItem(StoreCatalogItem item) async {
    if (_isSaving) {
      return;
    }

    if (item.type == StoreItemType.frame && _equippedFrameId == item.id) {
      setState(() {
        _isSaving = true;
      });
      try {
        await _authService.updateProfile(<String, dynamic>{
          'equippedAvatarFrameId': AvatarFrameCatalog.noneId,
        });
        _profileSnapshot['equippedAvatarFrameId'] = AvatarFrameCatalog.noneId;
        await _loadCatalog();
        _hasChanges = true;
        if (mounted) {
          _showToast('Moldura desequipada.');
        }
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
      return;
    }

    if (item.type == StoreItemType.background &&
        _equippedBackgroundId == item.id) {
      setState(() {
        _isSaving = true;
      });
      try {
        await _authService.updateProfile(<String, dynamic>{
          'equippedAvatarBackgroundId': AvatarFrameCatalog.noneId,
        });
        _profileSnapshot['equippedAvatarBackgroundId'] =
            AvatarFrameCatalog.noneId;
        await _loadCatalog();
        _hasChanges = true;
        if (mounted) {
          _showToast('Fundo desequipado.');
        }
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
      return;
    }

    await _buyOrEquip(item);
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
    final items = _selectedItems();

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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
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
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Todos',
                        onPressed: () {
                          setState(() {
                            _showOwnedOnly = false;
                          });
                        },
                        variant: _showOwnedOnly
                            ? AppButtonVariant.outline
                            : AppButtonVariant.primary,
                        textStyle: AppTextStyles.buttonSmall,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label: 'Habilitado',
                        onPressed: () {
                          setState(() {
                            _showOwnedOnly = true;
                          });
                        },
                        variant: _showOwnedOnly
                            ? AppButtonVariant.primary
                            : AppButtonVariant.outline,
                        textStyle: AppTextStyles.buttonSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
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
                        : items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xl,
                                ),
                                child: Text(
                                  'Sem itens disponíveis nesta categoria.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount =
                                  constraints.maxWidth >= 720 ? 3 : 2;
                              // Fundos: tile mais largo pra caber o banner
                              // na mesma proporcao do perfil (nao quadrado).
                              final childAspectRatio =
                                  _selectedCategory == StoreCategory.backgrounds
                                  ? 0.78
                                  : 1.0;
                              return GridView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xxxl,
                                ),
                                itemCount: items.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: AppSpacing.md,
                                  mainAxisSpacing: AppSpacing.md,
                                  childAspectRatio: childAspectRatio,
                                ),
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return _StoreTileEntrance(
                                    index: index,
                                    child: _StoreTile(
                                      item: item,
                                      avatarUrl: avatarUrl,
                                      name: name,
                                      blockerQuantity:
                                          _blockerInventory[item.id] ?? 0,
                                      blockerQuantityFallback:
                                          item.quantityOwned,
                                      isOwned: _isOwned(item),
                                      isEquipped: _isEquipped(item),
                                      canPurchase: _canPurchase(item),
                                      isSaving: _isSaving,
                                      onPreview: () => _previewItem(item),
                                      onPressed: () =>
                                          _toggleOwnedItem(item),
                                    ),
                                  );
                                },
                              );
                            },
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

class _StoreCategorySwitcher extends StatelessWidget {
  const _StoreCategorySwitcher({
    required this.selected,
    required this.onSelected,
  });

  final StoreCategory selected;
  final ValueChanged<StoreCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.performanceCardBorder, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CategoryButton(
              label: 'Bloqueadores',
              iconBuilder: (color) => Icon(
                Icons.shield_rounded,
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
              iconBuilder: (color) => FrameSilhouetteIcon(
                size: 26,
                color: color,
              ),
              isSelected: selected == StoreCategory.frames,
              onTap: () => onSelected(StoreCategory.frames),
            ),
          ),
          Expanded(
            child: _CategoryButton(
              label: 'Fundos',
              iconBuilder: (color) => Icon(
                Icons.landscape_rounded,
                size: 26,
                color: color,
              ),
              isSelected: selected == StoreCategory.backgrounds,
              onTap: () => onSelected(StoreCategory.backgrounds),
            ),
          ),
        ],
      ),
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
    return _PressableCategoryButton(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) {
            final iconColor = Color.lerp(
              AppColors.textSecondary,
              AppColors.action500,
              t,
            )!;
            final labelColor = Color.lerp(
              AppColors.textSecondary,
              AppColors.brand900Variant,
              t,
            )!;
            // Overshoot leve pra dar um "pop" na hora que vira selecionado.
            final pop = 1 + (math.sin(t * math.pi) * 0.1) + (t * 0.06);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: pop,
                  child: iconBuilder(iconColor),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionStrong.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.lerp(
                      FontWeight.w600,
                      FontWeight.w700,
                      t,
                    ),
                  ),
                ),
              ],
            );
          },
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        splashColor: AppColors.action500.withValues(alpha: 0.12),
        highlightColor: AppColors.action500.withValues(alpha: 0.06),
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _isPressed ? 0.92 : 1.0,
          duration: Duration(milliseconds: _isPressed ? 90 : 260),
          curve: _isPressed ? Curves.easeOut : Curves.easeOutBack,
          child: widget.child,
        ),
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
        Icon(
          Icons.monetization_on_rounded,
          size: 16,
          color: valueColor,
        ),
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
          const Icon(
            Icons.monetization_on_rounded,
            size: 14,
            color: AppColors.brand900Variant,
          ),
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
          const Icon(
            Icons.shield_rounded,
            size: 14,
            color: AppColors.action500,
          ),
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
    required this.canPurchase,
    required this.isSaving,
    required this.onPreview,
    required this.onPressed,
  });

  final StoreCatalogItem item;
  final String? avatarUrl;
  final String? name;
  final int blockerQuantity;
  final int blockerQuantityFallback;
  final bool isOwned;
  final bool isEquipped;
  final bool canPurchase;
  final bool isSaving;
  final VoidCallback onPreview;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final effectiveBlockerQuantity = blockerQuantity > 0
        ? blockerQuantity
        : blockerQuantityFallback;
    final label = item.isInventoryBlocker
        ? 'Comprar'
        : isEquipped
        ? 'Desequipar'
        : isOwned
        ? 'Equipar'
        : 'Comprar';
    final buttonEnabled = !isSaving;
    final metaLabel = item.isInventoryBlocker
        ? (effectiveBlockerQuantity > 0 ? 'x$effectiveBlockerQuantity' : ' ')
        : isOwned
        ? 'Comprado'
        : ' ';

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.none,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onPreview,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          clipBehavior: Clip.none,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: item.type == StoreItemType.background
                    ? Align(
                        alignment: Alignment.center,
                        child: _StoreItemPreview(
                          item: item,
                          avatarUrl: avatarUrl,
                          name: name,
                        ),
                      )
                    : Align(
                        alignment: const Alignment(0, -0.15),
                        child: _StoreItemPreview(
                          item: item,
                          avatarUrl: avatarUrl,
                          name: name,
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.name,
                style: AppTextStyles.homeMealTitle.copyWith(
                  color: AppColors.brand900Variant,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 16,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        metaLabel,
                        style: AppTextStyles.captionStrong.copyWith(
                          color: metaLabel.trim().isEmpty
                              ? Colors.transparent
                              : AppColors.action500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${item.priceGold}',
                      style: AppTextStyles.captionStrong.copyWith(
                        color: AppColors.brand900Variant,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.monetization_on_rounded,
                      size: 16,
                      color: AppColors.missionsRewardGold,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                label: label,
                onPressed: buttonEnabled ? onPressed : null,
                variant: isOwned && !item.isInventoryBlocker
                    ? AppButtonVariant.outline
                    : AppButtonVariant.primary,
                textStyle: AppTextStyles.buttonSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreTileEntrance extends StatelessWidget {
  const _StoreTileEntrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: 40 * index);

    return TweenAnimationBuilder<double>(
      key: ValueKey('store-tile-$index'),
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
    ).paddingOnly(delay: delay);
  }
}

extension on Widget {
  Widget paddingOnly({Duration? delay}) {
    return this;
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
              return ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.asset(
                  assetPath,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
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
              child: Icon(
                Icons.shield_rounded,
                size: iconSize,
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
