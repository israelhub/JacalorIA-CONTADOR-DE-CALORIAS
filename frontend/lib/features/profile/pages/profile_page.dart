import 'package:flutter/material.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/framed_avatar.dart';
import '../../../../shared/widgets/app_page_route.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/avatar_profile_preview.dart';
import '../../avatar_frames/models/avatar_frame_catalog.dart';
import '../../avatar_frames/pages/avatar_frame_store_page.dart';
import '../../auth/pages/enter_page.dart';
import '../../auth/service/auth_service.dart';
import '../../missions/services/missions_service.dart';
import '../../social/widgets/social_profile_info_card.dart';
import '../../social/widgets/social_profile_metric_card.dart';
import '../helpers/profile_date_helpers.dart';
import 'profile_edit_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.initialProfile});

  final Map<String, dynamic>? initialProfile;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

enum _ProfileCustomizationCategory { blockers, frames, covers, backgrounds }

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  final _missionsService = const MissionsService();

  Map<String, dynamic> _profileData = <String, dynamic>{};
  String? _avatarUrl;
  String _equippedAvatarFrameId = AvatarFrameCatalog.noneId;
  Set<String> _purchasedAvatarFrameIds = const <String>{};
  String _equippedCoverId = _ProfileCustomizationState.noneId;
  String _equippedBackgroundId = _ProfileCustomizationState.noneId;
  String? _equippedBlockerId;
  List<_ProfileCustomizationOption> _coverOptions =
      const <_ProfileCustomizationOption>[];
  List<_ProfileCustomizationOption> _backgroundOptions =
      const <_ProfileCustomizationOption>[];
  List<_ProfileBlockerOption> _blockerOptions = const <_ProfileBlockerOption>[];
  String? _coverPayloadKey;
  String? _backgroundPayloadKey;
  String? _blockerPayloadKey;
  bool _isSaving = false;
  bool _isSigningOut = false;
  bool _isContentReady = false;
  bool _isActionsExpanded = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackScreen('profile');
    _profileData = Map<String, dynamic>.from(
      widget.initialProfile ?? const <String, dynamic>{},
    );
    _hydrateProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isContentReady = true;
        });
      }
    });
  }

  void _hydrateProfile() {
    final profile = _profileData;

    _avatarUrl =
        (profile['avatarUrl'] as String?) ?? (profile['avatar_url'] as String?);
    _equippedAvatarFrameId = AvatarFrameCatalog.equippedIdFromProfile(profile);
    _purchasedAvatarFrameIds = AvatarFrameCatalog.purchasedIdsFromProfile(
      profile,
    );
    final personalization = _ProfileCustomizationState.fromProfile(profile);
    _equippedCoverId = personalization.equippedCoverId;
    _equippedBackgroundId = personalization.equippedBackgroundId;
    _equippedBlockerId = personalization.equippedBlockerId;
    _coverOptions = personalization.coverOptions;
    _backgroundOptions = personalization.backgroundOptions;
    _blockerOptions = personalization.blockerOptions;
    _coverPayloadKey = personalization.coverPayloadKey;
    _backgroundPayloadKey = personalization.backgroundPayloadKey;
    _blockerPayloadKey = personalization.blockerPayloadKey;
  }

  Future<void> _refreshProfileSnapshot() async {
    try {
      final profile = await _authService.fetchProfile();
      if (!mounted) return;
      setState(() {
        _profileData = Map<String, dynamic>.from(profile);
        _hydrateProfile();
      });
    } catch (_) {}
  }

  Future<void> _openEditDataPage() async {
    final updated = await context.pushSlidePage<bool>(
      ProfileEditPage(initialProfile: Map<String, dynamic>.from(_profileData)),
    );
    if (updated == true) {
      _hasChanges = true;
      await _refreshProfileSnapshot();
    }
  }

  Future<void> _openStorePage() async {
    final updated = await context.pushSlidePage<bool>(
      AvatarFrameStorePage(
        initialGoldBalance: _intFromKeys(const ['gold'], fallback: 0),
        profile: Map<String, dynamic>.from(_profileData),
        authService: _authService,
      ),
    );

    if (updated == true) {
      _hasChanges = true;
      await _refreshProfileSnapshot();
    }
  }

  // ignore: unused_element
  Future<void> _openPersonalizationSheet() async {
    StoreCatalogData? storeCatalog;
    try {
      final storeBody = await _missionsService.fetchStoreCatalog();
      storeCatalog = StoreCatalogData.fromJson(storeBody);
    } catch (_) {}

    final storeFrameById = {
      for (final item in storeCatalog?.frames ?? const <StoreCatalogItem>[])
        item.id: item,
    };
    final blockerPriceGold = storeCatalog?.blockers.isNotEmpty == true
        ? storeCatalog!.blockers.first.priceGold
        : 0;

    final result = await showModalBottomSheet<_ProfileCustomizationSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) {
        var selectedFrameId = _equippedAvatarFrameId;
        var selectedCoverId = _equippedCoverId;
        var selectedBackgroundId = _equippedBackgroundId;
        var selectedBlockerId = _equippedBlockerId;
        var selectedCategory = _ProfileCustomizationCategory.blockers;
        var showOwnedOnly = false;
        var isBuying = false;
        var frameOptions = AvatarFrameCatalog.items
            .where(
              (frame) =>
                  frame.id == AvatarFrameCatalog.noneId ||
                  storeFrameById.containsKey(frame.id) ||
                  _purchasedAvatarFrameIds.contains(frame.id),
            )
            .map(
              (frame) {
                final storeItem = storeFrameById[frame.id];
                return _ProfileCustomizationOption(
                  id: frame.id,
                  name: storeItem?.name ?? frame.name,
                  description: storeItem?.description ?? frame.description,
                  isOwned:
                      frame.id == AvatarFrameCatalog.noneId ||
                      _purchasedAvatarFrameIds.contains(frame.id),
                  priceGold: frame.id == AvatarFrameCatalog.noneId
                      ? 0
                      : (storeItem?.priceGold ?? 0),
                );
              },
            )
            .toList(growable: false);

        return StatefulBuilder(
          builder: (context, setModalState) {
            final selectedCover = _coverOptions.firstWhere(
              (item) => item.id == selectedCoverId,
              orElse: () => _coverOptions.first,
            );
            final selectedBackground = _backgroundOptions.firstWhere(
              (item) => item.id == selectedBackgroundId,
              orElse: () => _backgroundOptions.first,
            );
            final filteredFrameOptions = showOwnedOnly
                ? frameOptions
                      .where((option) => option.isOwned)
                      .toList(growable: false)
                : frameOptions;
            final filteredCoverOptions = showOwnedOnly
                ? _coverOptions
                      .where((option) => option.isOwned)
                      .toList(growable: false)
                : _coverOptions;
            final filteredBackgroundOptions = showOwnedOnly
                ? _backgroundOptions
                      .where((option) => option.isOwned)
                      .toList(growable: false)
                : _backgroundOptions;
            final filteredBlockers = showOwnedOnly
                ? _blockerOptions
                      .where((blocker) => blocker.quantity > 0)
                      .toList(growable: false)
                : _blockerOptions;

            Widget categoryBody;
            switch (selectedCategory) {
              case _ProfileCustomizationCategory.blockers:
                categoryBody = _BlockerSelector(
                  blockers: filteredBlockers,
                  selectedBlockerId: selectedBlockerId,
                  blockerUnitPriceGold: blockerPriceGold,
                  isBusy: isBuying,
                  onSelect: (value) {
                    setModalState(() {
                      selectedBlockerId = value;
                    });
                  },
                  onBuy: (blocker) async {
                    if (isBuying) return;
                    setModalState(() => isBuying = true);
                    try {
                      await _missionsService.purchaseBlocker(
                        blockerId: blocker.id,
                      );
                      await _refreshProfileSnapshot();
                    } catch (_) {
                    } finally {
                      if (mounted) {
                        setModalState(() => isBuying = false);
                      }
                    }
                  },
                );
                break;
              case _ProfileCustomizationCategory.frames:
                categoryBody = _CustomizationOptionWrap(
                  options: filteredFrameOptions,
                  selectedId: selectedFrameId,
                  isBusy: isBuying,
                  onSelect: (value) {
                    setModalState(() {
                      selectedFrameId = value;
                    });
                  },
                  onBuy: (option) async {
                    if (isBuying) return;
                    setModalState(() => isBuying = true);
                    try {
                      await _missionsService.purchaseAvatarFrame(option.id);
                      await _refreshProfileSnapshot();
                      setModalState(() {
                        frameOptions = AvatarFrameCatalog.items
                            .where(
                              (frame) =>
                                  frame.id == AvatarFrameCatalog.noneId ||
                                  storeFrameById.containsKey(frame.id) ||
                                  _purchasedAvatarFrameIds.contains(frame.id),
                            )
                            .map(
                              (frame) {
                                final storeItem = storeFrameById[frame.id];
                                return _ProfileCustomizationOption(
                                  id: frame.id,
                                  name: storeItem?.name ?? frame.name,
                                  description:
                                      storeItem?.description ?? frame.description,
                                  isOwned:
                                      frame.id == AvatarFrameCatalog.noneId ||
                                      _purchasedAvatarFrameIds.contains(
                                        frame.id,
                                      ),
                                  priceGold: frame.id == AvatarFrameCatalog.noneId
                                      ? 0
                                      : (storeItem?.priceGold ?? 0),
                                );
                              },
                            )
                            .toList(growable: false);
                        selectedFrameId = option.id;
                      });
                    } catch (_) {
                    } finally {
                      if (mounted) {
                        setModalState(() => isBuying = false);
                      }
                    }
                  },
                );
                break;
              case _ProfileCustomizationCategory.covers:
                categoryBody = _CustomizationOptionWrap(
                  options: filteredCoverOptions,
                  selectedId: selectedCoverId,
                  isBusy: isBuying,
                  onSelect: (value) {
                    setModalState(() {
                      selectedCoverId = value;
                    });
                  },
                );
                break;
              case _ProfileCustomizationCategory.backgrounds:
                categoryBody = _CustomizationOptionWrap(
                  options: filteredBackgroundOptions,
                  selectedId: selectedBackgroundId,
                  isBusy: isBuying,
                  onSelect: (value) {
                    setModalState(() {
                      selectedBackgroundId = value;
                    });
                  },
                  onBuy: (option) async {
                    if (isBuying) return;
                    setModalState(() => isBuying = true);
                    try {
                      await _missionsService.purchaseAvatarBackground(
                        option.id,
                      );
                      await _refreshProfileSnapshot();
                      setModalState(() {
                        selectedBackgroundId = option.id;
                      });
                    } catch (_) {
                    } finally {
                      if (mounted) {
                        setModalState(() => isBuying = false);
                      }
                    }
                  },
                );
                break;
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.lg,
                  bottom:
                      AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.performanceCardBorder,
                      ),
                      boxShadow: AppShadows.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personalize seu perfil',
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.brand900Variant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Escolha moldura, capa, fundo e bloqueadores.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _PersonalizationPreviewCard(
                          avatarUrl: _avatarUrl,
                          frameId: selectedFrameId,
                          fallbackText: _profileName,
                          cover: selectedCover,
                          background: selectedBackground,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment<bool>(
                              value: false,
                              label: Text('Tudo'),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              label: Text('Habilitado'),
                            ),
                          ],
                          selected: <bool>{showOwnedOnly},
                          onSelectionChanged: (selection) {
                            setModalState(() {
                              showOwnedOnly = selection.first;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _ProfileCustomizationCategorySwitcher(
                          selected: selectedCategory,
                          onSelected: (value) {
                            setModalState(() {
                              selectedCategory = value;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        categoryBody,
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton(
                            label: 'Salvar personalização',
                            onPressed: () {
                              Navigator.of(context).pop(
                                _ProfileCustomizationSelection(
                                  frameId: selectedFrameId,
                                  coverId: selectedCoverId,
                                  backgroundId: selectedBackgroundId,
                                  blockerId: selectedBlockerId,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      _equippedAvatarFrameId = result.frameId;
      _equippedCoverId = result.coverId;
      _equippedBackgroundId = result.backgroundId;
      _equippedBlockerId = result.blockerId;
    });

    await _savePersonalizationSelection();
  }

  Future<void> _savePersonalizationSelection() async {
    if (_isSaving) {
      return;
    }

    final data = <String, dynamic>{
      'equippedAvatarFrameId': _equippedAvatarFrameId,
      (_coverPayloadKey != null && _coverPayloadKey!.isNotEmpty)
              ? _coverPayloadKey!
              : 'equippedProfileCoverId':
          _equippedCoverId,
      (_backgroundPayloadKey != null && _backgroundPayloadKey!.isNotEmpty)
              ? _backgroundPayloadKey!
              : 'equippedAvatarBackgroundId':
          _equippedBackgroundId,
      (_blockerPayloadKey != null && _blockerPayloadKey!.isNotEmpty)
              ? _blockerPayloadKey!
              : 'equippedOffensiveBlockerId':
          _equippedBlockerId,
    };

    setState(() {
      _isSaving = true;
    });

    try {
      await _authService.updateProfile(data);
      await _refreshProfileSnapshot();
      if (mounted) {
        _hasChanges = true;
        AppToast.success(
          context,
          message: 'Personalização salva com sucesso.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, message: 'Erro ao salvar personalização: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    if (_isSigningOut || _isSaving) {
      return;
    }

    setState(() {
      _isSigningOut = true;
    });

    try {
      await _authService.signOut();
      if (!mounted) {
        return;
      }

      context.pushAndRemoveUntilSlidePage(const EnterPage(), (route) => false);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, message: 'Erro ao sair: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  String _stringFromKeys(List<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final value = _profileData[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return fallback;
  }

  int _intFromKeys(List<String> keys, {int fallback = 0}) {
    for (final key in keys) {
      final value = _profileData[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.round();
      }
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return fallback;
  }

  String _truncateWithEllipsis(String value, int maxChars) {
    if (value.length <= maxChars) {
      return value;
    }
    return '${value.substring(0, maxChars)}...';
  }

  String _normalizeLabel(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'Não informado';
    return raw[0].toUpperCase() +
        raw.substring(1).toLowerCase().replaceAll('_', ' ');
  }

  String _formatObjective(String? value) {
    final raw = (value ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z]'), '');
    if (raw.isEmpty) return 'Não informado';

    const labels = <String, String>{
      'loseweight': 'Emagrecer',
      'weightloss': 'Emagrecer',
      'cut': 'Emagrecer',
      'maintainweight': 'Manter peso',
      'maintenance': 'Manter peso',
      'maintain': 'Manter peso',
      'gainweight': 'Ganhar massa',
      'weightgain': 'Ganhar massa',
      'gainmass': 'Ganhar massa',
      'bulk': 'Ganhar massa',
      'gainmuscle': 'Ganhar massa',
      'musclegain': 'Ganhar massa',
      'recomposition': 'Recomposição corporal',
    };

    return labels[raw] ?? _normalizeLabel(value);
  }

  String _formatPreferredPeriod(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'morning':
        return 'Manhã';
      case 'afternoon':
        return 'Tarde';
      case 'night':
        return 'Noite';
      default:
        return 'Sem registros';
    }
  }

  String _formatActivityLevel(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'sedentary':
        return 'Sedentário';
      case 'lightly':
        return 'Levemente ativo';
      case 'moderate':
        return 'Moderadamente ativo';
      case 'very':
        return 'Muito ativo';
      case 'extreme':
        return 'Extremamente ativo';
      default:
        return 'Não informado';
    }
  }

  String get _profileName {
    final name = _stringFromKeys(const ['name']);
    return name.isEmpty ? 'Usuário' : name;
  }

  String _formatBirthDate() {
    final raw = _stringFromKeys(const ['birthDate', 'birth_date']);
    if (raw.isEmpty) {
      return 'Não informado';
    }
    return formatProfileDisplayDate(raw);
  }

  String _formatMeasure({required Object? rawValue, required String unit}) {
    if (rawValue == null) {
      return 'Não informado';
    }
    final value = rawValue is num
        ? rawValue.toStringAsFixed(rawValue % 1 == 0 ? 0 : 1)
        : rawValue.toString().trim();
    if (value.isEmpty) {
      return 'Não informado';
    }
    return unit.isEmpty ? value : '$value $unit';
  }

  Widget _sectionTitle(String value) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: AppTextStyles.missionsSectionTitle.copyWith(
          color: AppColors.brand900Variant,
        ),
      ),
    );
  }

  Widget _metricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return SocialProfileMetricCard(
      icon: icon,
      iconColor: iconColor,
      label: label,
      value: value,
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return SocialProfileInfoCard(
      icon: icon,
      iconColor: iconColor,
      label: label,
      value: value,
    );
  }

  @override
  Widget build(BuildContext context) {
    const summaryValueMaxChars = 14;
    final friendCount = _intFromKeys(const [
      'friendCount',
      'friendsCount',
      'friends_count',
    ], fallback: 0);
    final favoriteDishRaw = _stringFromKeys(const [
      'favoriteDish',
      'favorite_dish',
    ], fallback: 'Sem registros');
    final favoriteDish = favoriteDishRaw.trim().isEmpty
        ? 'Sem registros'
        : favoriteDishRaw;

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
          title: Text(
            'Perfil',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.brand900Variant,
            ),
          ),
        ),
        body: SafeArea(
          child: AnimatedOpacity(
            opacity: _isContentReady ? 1 : 0,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            child: AnimatedSlide(
              offset: _isContentReady ? Offset.zero : const Offset(0, 0.02),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AvatarProfilePreview(
                      avatarUrl: _avatarUrl,
                      frameId: _equippedAvatarFrameId,
                      backgroundId: _equippedBackgroundId,
                      name: _profileName,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.xl,
                        AppSpacing.xxxl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _profileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.left,
                                  style: AppTextStyles.missionsTitle.copyWith(
                                    color: AppColors.brand900Variant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  '$friendCount amigos',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _sectionTitle('Resumo'),
                          const SizedBox(height: AppSpacing.sm),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final maxWidth = constraints.maxWidth;
                              final spacing = AppSpacing.md;
                              const columns = 2;
                              final availableWidth =
                                  maxWidth - (spacing * (columns - 1));
                              final cardWidth = availableWidth > 0
                                  ? availableWidth / columns
                                  : maxWidth;

                              return Wrap(
                                spacing: spacing,
                                runSpacing: AppSpacing.md,
                                children: [
                                  SizedBox(
                                    width: cardWidth,
                                    child: _metricCard(
                                      icon: Icons.local_fire_department_rounded,
                                      iconColor: AppColors.socialMetricStreak,
                                      label: 'Sequência',
                                      value: _truncateWithEllipsis(
                                        '${_intFromKeys(const ['streakDays', 'streak_days'])} dias',
                                        summaryValueMaxChars,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: _metricCard(
                                      icon: Icons.restaurant_menu_rounded,
                                      iconColor:
                                          AppColors.socialMetricFavoriteDish,
                                      label: 'Prato favorito',
                                      value: _truncateWithEllipsis(
                                        favoriteDish,
                                        summaryValueMaxChars,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: _metricCard(
                                      icon: Icons.schedule_rounded,
                                      iconColor:
                                          AppColors.socialMetricPreferredPeriod,
                                      label: 'Come mais de',
                                      value: _truncateWithEllipsis(
                                        _formatPreferredPeriod(
                                          _stringFromKeys(const [
                                            'preferredPeriod',
                                            'preferred_period',
                                          ]),
                                        ),
                                        summaryValueMaxChars,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: cardWidth,
                                    child: _metricCard(
                                      icon: Icons.auto_awesome_rounded,
                                      iconColor: AppColors.socialMetricXp,
                                      label: 'Total de XP',
                                      value: _truncateWithEllipsis(
                                        '${_intFromKeys(const ['totalXp', 'total_xp', 'xp'])}',
                                        summaryValueMaxChars,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _sectionTitle('Informações adicionais'),
                          const SizedBox(height: AppSpacing.sm),
                          _infoCard(
                            icon: Icons.cake_rounded,
                            iconColor: AppColors.socialInfoBirthDateBase,
                            label: 'Data de nascimento',
                            value: _formatBirthDate(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _infoCard(
                            icon: Icons.person_rounded,
                            iconColor: AppColors.socialInfoSex,
                            label: 'Sexo',
                            value: _normalizeLabel(
                              _stringFromKeys(const ['sex'], fallback: ''),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _infoCard(
                            icon: Icons.flag_rounded,
                            iconColor: AppColors.socialInfoObjective,
                            label: 'Objetivo',
                            value: _formatObjective(
                              _stringFromKeys(const [
                                'objective',
                              ], fallback: ''),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _infoCard(
                            icon: Icons.directions_run_rounded,
                            iconColor: AppColors.socialInfoObjective,
                            label: 'Nível de atividade',
                            value: _formatActivityLevel(
                              _stringFromKeys(const [
                                'activityLevel',
                                'activity_level',
                              ]),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _infoCard(
                            icon: Icons.fitness_center_rounded,
                            iconColor: AppColors.socialInfoObjective,
                            label: 'Peso',
                            value: _formatMeasure(
                              rawValue: _profileData['weight'],
                              unit: _stringFromKeys(const [
                                'weightUnit',
                                'weight_unit',
                              ]),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _infoCard(
                            icon: Icons.height_rounded,
                            iconColor: AppColors.socialInfoObjective,
                            label: 'Altura',
                            value: _formatMeasure(
                              rawValue: _profileData['height'],
                              unit: _stringFromKeys(const [
                                'heightUnit',
                                'height_unit',
                              ]),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          SizedBox(
                            height: AppSpacing.huge + AppSpacing.xs,
                            child: AppButton(
                              label: _isSigningOut ? 'Saindo...' : 'Sair',
                              onPressed: (_isSaving || _isSigningOut)
                                  ? null
                                  : _signOut,
                              variant: AppButtonVariant.danger,
                              trailingIcon: Icons.door_front_door_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_isActionsExpanded) ...[
              SizedBox(
                width: 220,
                child: AppButton(
                  label: 'Editar dados pessoais',
                  onPressed: () async {
                    setState(() => _isActionsExpanded = false);
                    await _openEditDataPage();
                  },
                  variant: AppButtonVariant.outline,
                  leadingIcon: Icons.badge_rounded,
                  textStyle: AppTextStyles.buttonSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: 220,
                child: AppButton(
                  label: 'Personalizar perfil',
                  onPressed: () async {
                    setState(() => _isActionsExpanded = false);
                    await _openStorePage();
                  },
                  variant: AppButtonVariant.outline,
                  leadingIcon: Icons.storefront_rounded,
                  textStyle: AppTextStyles.buttonSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            _ProfileActionToggleButton(
              icon: _isActionsExpanded ? Icons.close_rounded : Icons.edit_rounded,
              onPressed: () {
                setState(() {
                  _isActionsExpanded = !_isActionsExpanded;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCustomizationCategorySwitcher extends StatelessWidget {
  const _ProfileCustomizationCategorySwitcher({
    required this.selected,
    required this.onSelected,
  });

  final _ProfileCustomizationCategory selected;
  final ValueChanged<_ProfileCustomizationCategory> onSelected;

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
              icon: Icons.shield_rounded,
              isSelected: selected == _ProfileCustomizationCategory.blockers,
              onTap: () => onSelected(_ProfileCustomizationCategory.blockers),
            ),
          ),
          Expanded(
            child: _CategoryButton(
              label: 'Molduras',
              icon: Icons.crop_rounded,
              isSelected: selected == _ProfileCustomizationCategory.frames,
              onTap: () => onSelected(_ProfileCustomizationCategory.frames),
            ),
          ),
          Expanded(
            child: _CategoryButton(
              label: 'Capa',
              icon: Icons.view_carousel_rounded,
              isSelected: selected == _ProfileCustomizationCategory.covers,
              onTap: () => onSelected(_ProfileCustomizationCategory.covers),
            ),
          ),
          Expanded(
            child: _CategoryButton(
              label: 'Fundos',
              icon: Icons.landscape_rounded,
              isSelected: selected == _ProfileCustomizationCategory.backgrounds,
              onTap: () =>
                  onSelected(_ProfileCustomizationCategory.backgrounds),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionToggleButton extends StatefulWidget {
  const _ProfileActionToggleButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_ProfileActionToggleButton> createState() =>
      _ProfileActionToggleButtonState();
}

class _ProfileActionToggleButtonState extends State<_ProfileActionToggleButton> {
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
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        offset: Offset(0, _isPressed ? 0.012 : 0),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutBack,
          scale: _isPressed ? 0.965 : 1,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.action500,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: AppColors.action500Shadow,
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(widget.icon, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? AppColors.action500
                    : AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.captionStrong.copyWith(
                  color: isSelected
                      ? AppColors.brand900Variant
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomizationOptionWrap extends StatelessWidget {
  const _CustomizationOptionWrap({
    required this.options,
    required this.selectedId,
    required this.onSelect,
    this.onBuy,
    this.isBusy = false,
  });

  final List<_ProfileCustomizationOption> options;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final ValueChanged<_ProfileCustomizationOption>? onBuy;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Text(
        'Nenhuma opção disponível por enquanto.',
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 320;
        final cardWidth = useTwoColumns
            ? (constraints.maxWidth - AppSpacing.sm) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: options
              .map((option) {
                final isSelected = selectedId == option.id;
                final isEnabled = option.isOwned;
                final badgeLabel = isEnabled ? null : 'Bloqueado';
                return SizedBox(
                  width: cardWidth,
                  child: _PersonalizationOptionCard(
                    title: option.name,
                    subtitle: option.description,
                    isSelected: isSelected,
                    isEnabled: isEnabled,
                    badgeLabel: badgeLabel,
                    onTap: isEnabled ? () => onSelect(option.id) : null,
                    onBuy: !isEnabled && onBuy != null
                        ? () => onBuy!(option)
                        : null,
                    priceGold: option.priceGold,
                    isBusy: isBusy,
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }
}

class _BlockerSelector extends StatelessWidget {
  const _BlockerSelector({
    required this.blockers,
    required this.selectedBlockerId,
    required this.onSelect,
    required this.onBuy,
    required this.blockerUnitPriceGold,
    this.isBusy = false,
  });

  final List<_ProfileBlockerOption> blockers;
  final String? selectedBlockerId;
  final ValueChanged<String?> onSelect;
  final ValueChanged<_ProfileBlockerOption> onBuy;
  final int blockerUnitPriceGold;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    if (blockers.isEmpty) {
      return Text(
        'Você ainda não tem bloqueadores disponíveis.',
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      );
    }

    return Column(
      children: blockers
          .map((blocker) {
            final isSelected = selectedBlockerId == blocker.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PersonalizationOptionCard(
                title: blocker.name,
                subtitle: '${blocker.description}${blocker.quantityText}',
                isSelected: isSelected,
                isEnabled: blocker.isOwned,
                badgeLabel: blocker.isOwned
                    ? (isSelected ? 'Equipado' : 'Disponível')
                    : 'Sem unidades',
                onTap: blocker.isOwned
                    ? () => onSelect(isSelected ? null : blocker.id)
                    : null,
                priceGold: blocker.isOwned ? 0 : blockerUnitPriceGold,
                onBuy: blocker.isOwned ? null : () => onBuy(blocker),
                isBusy: isBusy,
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _PersonalizationOptionCard extends StatelessWidget {
  const _PersonalizationOptionCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
    this.badgeLabel,
    this.onBuy,
    this.priceGold = 0,
    this.isBusy = false,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback? onTap;
  final String? badgeLabel;
  final VoidCallback? onBuy;
  final int priceGold;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.action500
        : AppColors.performanceCardBorder;
    final backgroundColor = isEnabled
        ? AppColors.surface
        : AppColors.surfaceAlt;
    final titleColor = isEnabled
        ? AppColors.brand900Variant
        : AppColors.textSecondary;
    final subtitleColor = isEnabled
        ? AppColors.textSecondary
        : AppColors.textTertiary;
    final indicatorColor = isSelected
        ? AppColors.action500
        : AppColors.borderAlt;
    final indicatorIcon = isSelected
        ? Icons.check_rounded
        : isEnabled
        ? Icons.circle_outlined
        : Icons.lock_outline_rounded;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1.5),
            boxShadow: isSelected ? AppShadows.sm : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.action500.withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: indicatorColor),
                    ),
                    child: Icon(indicatorIcon, size: 12, color: indicatorColor),
                  ),
                  const Spacer(),
                  if (badgeLabel != null)
                    Text(
                      badgeLabel!,
                      style: AppTextStyles.captionStrong.copyWith(
                        color: isEnabled
                            ? AppColors.action500
                            : AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(color: subtitleColor),
              ),
              if (!isEnabled && priceGold > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      size: 14,
                      color: AppColors.missionsRewardGold,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$priceGold',
                      style: AppTextStyles.captionStrong.copyWith(
                        color: AppColors.brand900Variant,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: isBusy ? null : onBuy,
                      child: const Text('Comprar'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonalizationPreviewCard extends StatelessWidget {
  const _PersonalizationPreviewCard({
    required this.avatarUrl,
    required this.frameId,
    required this.fallbackText,
    required this.cover,
    required this.background,
  });

  final String? avatarUrl;
  final String frameId;
  final String fallbackText;
  final _ProfileCustomizationOption cover;
  final _ProfileCustomizationOption background;

  @override
  Widget build(BuildContext context) {
    final backgroundImage = _resolveImage(background.imageUrl);
    final coverImage = _resolveImage(cover.imageUrl);

    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: AppColors.homeProgressTrack,
        image: backgroundImage,
      ),
      child: Stack(
        children: [
          if (coverImage != null)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  image: coverImage,
                ),
              ),
            ),
          Center(
            child: FramedAvatar(
              size: AppSpacing.huge * 1.8,
              avatarUrl: avatarUrl,
              frameId: frameId,
              fallbackText: fallbackText,
            ),
          ),
        ],
      ),
    );
  }

  DecorationImage? _resolveImage(String? rawUrl) {
    final url = rawUrl?.trim();
    if (url == null || url.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return null;
    }

    return DecorationImage(image: NetworkImage(url), fit: BoxFit.cover);
  }
}

class _ProfileCustomizationSelection {
  const _ProfileCustomizationSelection({
    required this.frameId,
    required this.coverId,
    required this.backgroundId,
    required this.blockerId,
  });

  final String frameId;
  final String coverId;
  final String backgroundId;
  final String? blockerId;
}

class _ProfileCustomizationOption {
  const _ProfileCustomizationOption({
    required this.id,
    required this.name,
    required this.description,
    required this.isOwned,
    this.imageUrl,
    this.priceGold = 0,
  });

  final String id;
  final String name;
  final String description;
  final bool isOwned;
  final String? imageUrl;
  final int priceGold;

  _ProfileCustomizationOption copyWith({bool? isOwned}) {
    return _ProfileCustomizationOption(
      id: id,
      name: name,
      description: description,
      isOwned: isOwned ?? this.isOwned,
      imageUrl: imageUrl,
      priceGold: priceGold,
    );
  }
}

class _ProfileBlockerOption {
  const _ProfileBlockerOption({
    required this.id,
    required this.name,
    required this.description,
    required this.isOwned,
    required this.quantity,
  });

  final String id;
  final String name;
  final String description;
  final bool isOwned;
  final int quantity;

  String get quantityText => quantity > 0 ? ' • $quantity disponível' : '';
}

class _ProfileCustomizationState {
  const _ProfileCustomizationState({
    required this.equippedCoverId,
    required this.equippedBackgroundId,
    required this.equippedBlockerId,
    required this.coverOptions,
    required this.backgroundOptions,
    required this.blockerOptions,
    required this.coverPayloadKey,
    required this.backgroundPayloadKey,
    required this.blockerPayloadKey,
  });

  static const String noneId = 'none';

  final String equippedCoverId;
  final String equippedBackgroundId;
  final String? equippedBlockerId;
  final List<_ProfileCustomizationOption> coverOptions;
  final List<_ProfileCustomizationOption> backgroundOptions;
  final List<_ProfileBlockerOption> blockerOptions;
  final String? coverPayloadKey;
  final String? backgroundPayloadKey;
  final String? blockerPayloadKey;

  static _ProfileCustomizationState fromProfile(Map<String, dynamic> profile) {
    final coverPayloadKey = _firstExistingKey(profile, const <String>[
      'equippedProfileCoverId',
      'equipped_profile_cover_id',
      'profileCoverId',
      'profile_cover_id',
    ]);
    final backgroundPayloadKey = _firstExistingKey(profile, const <String>[
      'equippedAvatarBackgroundId',
      'equipped_avatar_background_id',
      'equippedProfileBackgroundId',
      'equipped_profile_background_id',
      'profileBackgroundId',
      'profile_background_id',
      'equippedProfileBackdropId',
      'equipped_profile_backdrop_id',
    ]);
    final blockerPayloadKey = _firstExistingKey(profile, const <String>[
      'equippedOffensiveBlockerId',
      'equipped_offensive_blocker_id',
      'equippedBlockerId',
      'equipped_blocker_id',
      'activeBlockerId',
      'active_blocker_id',
      'selectedBlockerId',
      'selected_blocker_id',
    ]);

    final coverId =
        _stringFromKeys(profile, const <String>[
          'equippedProfileCoverId',
          'equipped_profile_cover_id',
          'profileCoverId',
          'profile_cover_id',
        ]) ??
        noneId;
    final backgroundId =
        _stringFromKeys(profile, const <String>[
          'equippedAvatarBackgroundId',
          'equipped_avatar_background_id',
          'equippedProfileBackgroundId',
          'equipped_profile_background_id',
          'profileBackgroundId',
          'profile_background_id',
          'equippedProfileBackdropId',
          'equipped_profile_backdrop_id',
        ]) ??
        noneId;
    final blockerId = _stringFromKeys(profile, const <String>[
      'equippedOffensiveBlockerId',
      'equipped_offensive_blocker_id',
      'equippedBlockerId',
      'equipped_blocker_id',
      'activeBlockerId',
      'active_blocker_id',
      'selectedBlockerId',
      'selected_blocker_id',
    ]);

    final ownedCoverIds = _stringSetFromKeys(profile, const <String>[
      'purchasedProfileCoverIds',
      'purchased_profile_cover_ids',
      'ownedProfileCoverIds',
      'owned_profile_cover_ids',
      'profileCoverInventoryIds',
      'profile_cover_inventory_ids',
    ]);
    final ownedBackgroundIds = _stringSetFromKeys(profile, const <String>[
      'purchasedAvatarBackgroundIds',
      'purchased_avatar_background_ids',
      'purchasedProfileBackgroundIds',
      'purchased_profile_background_ids',
      'ownedProfileBackgroundIds',
      'owned_profile_background_ids',
      'profileBackgroundInventoryIds',
      'profile_background_inventory_ids',
      'purchasedProfileBackdropIds',
      'purchased_profile_backdrop_ids',
    ]);
    final rawCoverOptions = _listFromKeys(profile, const <String>[
      'profileCoverOptions',
      'profile_cover_options',
      'coverOptions',
      'cover_options',
      'profileCovers',
      'profile_covers',
      'covers',
    ]);
    final rawBackgroundOptions = _listFromKeys(profile, const <String>[
      'profileBackgroundOptions',
      'profile_background_options',
      'backgroundOptions',
      'background_options',
      'profileBackgrounds',
      'profile_backgrounds',
      'backgrounds',
      'profileBackdropOptions',
      'profile_backdrop_options',
    ]);
    final rawBlockers = _listFromKeys(profile, const <String>[
      'profileBlockers',
      'profile_blockers',
      'blockerInventory',
      'blocker_inventory',
      'offensiveBlockers',
      'offensive_blockers',
      'availableBlockers',
      'available_blockers',
      'blockers',
    ]);

    final coverOptions = _buildCustomizationOptions(
      rawOptions: rawCoverOptions,
      ownedIds: ownedCoverIds,
      noneLabel: 'Sem capa',
      noneDescription: 'Visual limpo sem capa.',
      selectedId: coverId,
    );
    final backgroundOptions = _buildCustomizationOptions(
      rawOptions: rawBackgroundOptions,
      ownedIds: ownedBackgroundIds,
      noneLabel: 'Sem fundo',
      noneDescription: 'Sem fundo adicional no perfil.',
      selectedId: backgroundId,
    );
    final blockerOptions = _buildBlockerOptions(
      rawBlockers,
      blockerId,
      fallbackInventoryCount: _intFromKeys(profile, const <String>[
        'offensiveBlockerInventoryCount',
        'offensive_blocker_inventory_count',
      ]),
      fallbackBlockerId:
          _stringFromKeys(profile, const <String>[
            'equippedOffensiveBlockerId',
            'equipped_offensive_blocker_id',
          ]) ??
          'offensive_guard',
    );

    return _ProfileCustomizationState(
      equippedCoverId: coverOptions.any((item) => item.id == coverId)
          ? coverId
          : noneId,
      equippedBackgroundId:
          backgroundOptions.any((item) => item.id == backgroundId)
          ? backgroundId
          : noneId,
      equippedBlockerId: blockerOptions.any((item) => item.id == blockerId)
          ? blockerId
          : null,
      coverOptions: coverOptions,
      backgroundOptions: backgroundOptions,
      blockerOptions: blockerOptions,
      coverPayloadKey: coverPayloadKey,
      backgroundPayloadKey: backgroundPayloadKey,
      blockerPayloadKey: blockerPayloadKey,
    );
  }

  static List<_ProfileCustomizationOption> _buildCustomizationOptions({
    required List<dynamic> rawOptions,
    required Set<String> ownedIds,
    required String noneLabel,
    required String noneDescription,
    required String selectedId,
  }) {
    final options = <_ProfileCustomizationOption>[
      _ProfileCustomizationOption(
        id: noneId,
        name: noneLabel,
        description: noneDescription,
        isOwned: true,
      ),
    ];
    final knownIds = <String>{noneId};

    for (final item in rawOptions) {
      final option = _optionFromDynamic(item, ownedIds);
      if (option == null || knownIds.contains(option.id)) {
        continue;
      }
      options.add(option);
      knownIds.add(option.id);
    }

    for (final id in ownedIds) {
      if (knownIds.contains(id)) {
        continue;
      }
      options.add(
        _ProfileCustomizationOption(
          id: id,
          name: _displayFromId(id),
          description: 'Item liberado para o seu perfil.',
          isOwned: true,
        ),
      );
      knownIds.add(id);
    }

    if (selectedId != noneId && selectedId.trim().isNotEmpty) {
      final normalized = selectedId.trim();
      if (!knownIds.contains(normalized)) {
        options.add(
          _ProfileCustomizationOption(
            id: normalized,
            name: _displayFromId(normalized),
            description: 'Item já equipado no seu perfil.',
            isOwned: true,
          ),
        );
      }
    }

    return options;
  }

  static _ProfileCustomizationOption? _optionFromDynamic(
    dynamic value,
    Set<String> ownedIds,
  ) {
    if (value is String) {
      final id = value.trim();
      if (id.isEmpty) {
        return null;
      }
      return _ProfileCustomizationOption(
        id: id,
        name: _displayFromId(id),
        description: 'Item de personalização.',
        isOwned: ownedIds.contains(id),
        priceGold: 0,
      );
    }

    if (value is! Map<String, dynamic>) {
      return null;
    }

    final id = _stringFromKeys(value, const <String>[
      'id',
      'key',
      'coverId',
      'backgroundId',
      'backdropId',
    ]);
    if (id == null || id.isEmpty) {
      return null;
    }

    final normalizedId = id.trim();
    final name =
        _stringFromKeys(value, const <String>['name', 'title', 'label']) ??
        _displayFromId(normalizedId);
    final description =
        _stringFromKeys(value, const <String>[
          'description',
          'subtitle',
          'shortDescription',
        ]) ??
        'Item de personalização.';
    final imageUrl = _stringFromKeys(value, const <String>[
      'imageUrl',
      'image_url',
      'coverUrl',
      'cover_url',
      'backgroundUrl',
      'background_url',
      'assetUrl',
      'asset_url',
    ]);
    final isOwned =
        _boolFromKeys(value, const <String>['isOwned', 'owned']) ??
        ownedIds.contains(normalizedId);
    final priceGold = _intFromKeys(value, const <String>[
      'priceGold',
      'price_gold',
      'price',
      'goldCost',
      'gold_cost',
    ]);

    return _ProfileCustomizationOption(
      id: normalizedId,
      name: name,
      description: description,
      isOwned: isOwned,
      imageUrl: imageUrl,
      priceGold: priceGold,
    );
  }

  static List<_ProfileBlockerOption> _buildBlockerOptions(
    List<dynamic> rawBlockers,
    String? selectedBlockerId, {
    required int fallbackInventoryCount,
    required String fallbackBlockerId,
  }) {
    final result = <_ProfileBlockerOption>[];
    final knownIds = <String>{};

    for (final item in rawBlockers) {
      if (item is String) {
        final id = item.trim();
        if (id.isEmpty || knownIds.contains(id)) {
          continue;
        }
        result.add(
          _ProfileBlockerOption(
            id: id,
            name: _displayFromId(id),
            description: 'Bloqueador pronto para uso.',
            isOwned: true,
            quantity: 1,
          ),
        );
        knownIds.add(id);
        continue;
      }

      if (item is! Map<String, dynamic>) {
        continue;
      }

      final id = _stringFromKeys(item, const <String>[
        'id',
        'key',
        'blockerId',
        'blocker_id',
      ]);
      if (id == null || id.trim().isEmpty) {
        continue;
      }

      final normalizedId = id.trim();
      if (knownIds.contains(normalizedId)) {
        continue;
      }

      final name =
          _stringFromKeys(item, const <String>['name', 'title', 'label']) ??
          _displayFromId(normalizedId);
      final description =
          _stringFromKeys(item, const <String>[
            'description',
            'subtitle',
            'shortDescription',
          ]) ??
          'Protege um dia no calendário.';
      final quantity = _intFromKeys(item, const <String>[
        'quantity',
        'count',
        'amount',
        'available',
      ]);
      final isOwned =
          (_boolFromKeys(item, const <String>['isOwned', 'owned']) ?? false) ||
          quantity > 0;

      result.add(
        _ProfileBlockerOption(
          id: normalizedId,
          name: name,
          description: description,
          isOwned: isOwned,
          quantity: quantity,
        ),
      );
      knownIds.add(normalizedId);
    }

    if (selectedBlockerId != null &&
        selectedBlockerId.trim().isNotEmpty &&
        !knownIds.contains(selectedBlockerId.trim())) {
      final id = selectedBlockerId.trim();
      result.add(
        _ProfileBlockerOption(
          id: id,
          name: _displayFromId(id),
          description: 'Bloqueador equipado.',
          isOwned: true,
          quantity: 1,
        ),
      );
    }

    if (result.isEmpty && fallbackInventoryCount > 0) {
      result.add(
        _ProfileBlockerOption(
          id: fallbackBlockerId,
          name: _displayFromId(fallbackBlockerId),
          description: 'Protege um dia no calendário.',
          isOwned: true,
          quantity: fallbackInventoryCount,
        ),
      );
    }

    return result;
  }

  static String? _firstExistingKey(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (data.containsKey(key)) {
        return key;
      }
    }
    return null;
  }

  static String? _stringFromKeys(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static Set<String> _stringSetFromKeys(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final raw = data[key];
      final values = raw is Iterable
          ? raw
          : raw is String
          ? raw.split(',')
          : const <Object?>[];
      final normalized = values
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toSet();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }

    return <String>{};
  }

  static List<dynamic> _listFromKeys(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final raw = data[key];
      if (raw is List<dynamic>) {
        return raw;
      }
      if (raw is Iterable) {
        return raw.toList(growable: false);
      }
    }
    return const <dynamic>[];
  }

  static bool? _boolFromKeys(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value > 0;
      }
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') {
          return true;
        }
        if (normalized == 'false' || normalized == '0') {
          return false;
        }
      }
    }
    return null;
  }

  static int _intFromKeys(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.round();
      }
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return 0;
  }

  static String _displayFromId(String id) {
    final cleaned = id.trim();
    if (cleaned.isEmpty) {
      return 'Item';
    }

    return cleaned
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
