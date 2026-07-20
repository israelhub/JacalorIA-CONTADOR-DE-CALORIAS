import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../avatar_frames/pages/avatar_frame_store_page.dart';
import '../../auth/service/auth_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_guide_card.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_refresh_scroll_view.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../models/missions_overview.dart';
import '../services/missions_service.dart';
import '../widgets/mission_card.dart';

class MissionsPage extends StatefulWidget {
  const MissionsPage({
    super.key,
    MissionsService? service,
    this.authService,
    this.refreshVersion = 0,
  })
    : _service = service ?? const MissionsService();

  final MissionsService _service;
  final AuthService? authService;
  final int refreshVersion;

  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> {
  static const String _hideIntroLocalKey = 'missions_hide_intro_local';
  MissionsOverview? _overview;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _showIntro = true;
  String? _errorMessage;

  bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  bool _isGuideHidden(Map<String, dynamic> profile) {
    return _asBool(profile['hideGuideMe']) ||
        _asBool(profile['hideSocialGuideMe']) ||
        _asBool(profile['hideMissionsGuideMe']) ||
        _asBool(profile['hide_guide_me']) ||
        _asBool(profile['hide_social_guide_me']) ||
        _asBool(profile['hide_missions_guide_me']);
  }

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  @override
  void didUpdateWidget(covariant MissionsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshVersion != oldWidget.refreshVersion) {
      _loadMissions(silent: true);
    }
  }

  List<MissionItem> _sortedMissions(List<MissionItem> missions) {
    final sorted = List<MissionItem>.from(missions);
    sorted.sort((a, b) {
      if (a.isCompleted == b.isCompleted) {
        return 0;
      }
      return a.isCompleted ? 1 : -1;
    });
    return sorted;
  }

  Future<void> _loadMissions({bool silent = false}) async {
    final hadData = _overview != null;
    if (!silent || _overview == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      _errorMessage = null;
    }

    try {
      final results = await Future.wait<dynamic>([
        widget._service.fetchMissions(),
        (widget.authService ?? AuthService()).fetchProfile().catchError((_) {
          return <String, dynamic>{};
        }),
      ]);

      final result = results[0] as MissionsOverview;
      final profile = results[1] as Map<String, dynamic>;
      final hideIntroLocal = await _readHideIntroLocal();
      if (!mounted) {
        return;
      }

      setState(() {
        _overview = result;
        _profile = profile;
        _showIntro = !(hideIntroLocal || _isGuideHidden(profile));
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (!silent || !hadData) {
          _errorMessage = error.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        }
      });
    }
  }

  Future<bool> _readHideIntroLocal() async {
    try {
      final authUser = AuthService.globalUser;
      final rawUserId =
          authUser?['id'] ?? authUser?['email'] ?? authUser?['name'] ?? 'user';
      final userId = rawUserId.toString();
      final key = '$_hideIntroLocalKey:$userId';
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.action500),
      );
    }

    if (_errorMessage != null || _overview == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _errorMessage ?? 'Não foi possível carregar as missões.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: 'Tentar novamente', onPressed: _loadMissions),
            ],
          ),
        ),
      );
    }

    final overview = _overview!;

    return AppRefreshScrollView(
      onRefresh: () => _loadMissions(silent: true),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppPageHeader(
            title: 'Missões',
            icon: Icons.local_fire_department_rounded,
            iconSize: 26,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _CounterPill(
                  value: overview.gold.toString(),
                  icon: Icons.monetization_on_rounded,
                  background: AppColors.missionsGoldPill,
                  onTap: _openGoldStatement,
                ),
                const SizedBox(width: AppSpacing.sm),
                _CounterPill(
                  value: overview.xp.toString(),
                  icon: Icons.bolt_rounded,
                  background: AppColors.missionsXpPill,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_showIntro) ...<Widget>[
            AppGuideCard(
              title: overview.introTitle,
              description: overview.introDescription,
              icon: Icons.campaign_rounded,
              backgroundColor: AppColors.action500,
              iconBackgroundColor: AppColors.missionsIntroIcon,
              iconColor: AppColors.surface,
              titleStyle: AppTextStyles.missionsIntroTitle.copyWith(
                color: AppColors.surface,
              ),
              descriptionStyle: AppTextStyles.missionsIntroDescription.copyWith(
                color: AppColors.surface,
              ),
              onClose: () {
                setState(() {
                  _showIntro = false;
                });
                _persistGuidePreference();
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _AvatarFrameStoreBanner(onPressed: _openStore),
          const SizedBox(height: AppSpacing.lg),
          for (final section in overview.sections) ...<Widget>[
            AppSectionHeader(title: section.title, subtitle: section.subtitle),
            const SizedBox(height: AppSpacing.lg),
            for (final mission in _sortedMissions(
              section.missions,
            )) ...<Widget>[
              MissionCard(mission: mission),
              const SizedBox(height: AppSpacing.lg),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _persistGuidePreference() async {
    try {
      await (widget.authService ?? AuthService()).updateProfile(
        <String, dynamic>{
          'hideGuideMe': true,
          'hideMissionsGuideMe': true,
          'hideSocialGuideMe': true,
        },
      );
    } catch (_) {}
    try {
      final authUser = AuthService.globalUser;
      final rawUserId =
          authUser?['id'] ?? authUser?['email'] ?? authUser?['name'] ?? 'user';
      final userId = rawUserId.toString();
      final key = '$_hideIntroLocalKey:$userId';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, true);
    } catch (_) {}
  }

  Future<void> _openStore() async {
    final overview = _overview;
    final profile = _profile;
    if (overview == null || profile == null) {
      return;
    }

    final changed = await context.pushSlidePage<bool>(
      AvatarFrameStorePage(
        initialGoldBalance: overview.gold,
        initialGoldLifetimeEarned: overview.goldLifetimeEarned,
        initialGoldLifetimeSpent: overview.goldLifetimeSpent,
        profile: profile,
        authService: widget.authService,
      ),
    );

    if (changed == true && mounted) {
      _loadMissions();
    }
  }

  Future<void> _openGoldStatement() async {
    await context.pushSlidePage<void>(
      _GoldStatementPage(service: widget._service),
    );
    if (mounted) {
      _loadMissions();
    }
  }
}

class _AvatarFrameStoreBanner extends StatelessWidget {
  const _AvatarFrameStoreBanner({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.performanceCardBorder, width: 2),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.missionsGoldPill,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.missionsRewardGold,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loja',
                  style: AppTextStyles.homeSectionTitle.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Compre bloqueadores, molduras e fundos com seu ouro.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 92,
            child: AppButton(
              label: 'Abrir',
              onPressed: onPressed,
              variant: AppButtonVariant.outline,
              textStyle: AppTextStyles.buttonSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({
    required this.value,
    required this.icon,
    required this.background,
    this.onTap,
  });

  final String value;
  final IconData icon;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          height: 31,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.performanceCardBorder),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 14, color: AppColors.brand900Variant),
              const SizedBox(width: AppSpacing.xs),
              Text(
                value,
                style: AppTextStyles.missionsPillValue.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldStatementPage extends StatelessWidget {
  const _GoldStatementPage({required this.service});

  final MissionsService service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        title: Text(
          'Extrato de ouro',
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: service.fetchGoldStatement(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.action500),
            );
          }

          if (snapshot.hasError) {
            final message =
                snapshot.error?.toString().replaceFirst('Exception: ', '') ??
                'Erro ao carregar extrato.';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }

          final entries = snapshot.data ?? const <Map<String, dynamic>>[];
          if (entries.isEmpty) {
            return Center(
              child: Text(
                'Ainda não há movimentações de ouro.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final amount = _toInt(
                entry['amountSigned'] ?? entry['amount'] ?? entry['value'],
              );
              final isCredit = amount >= 0;
              final type =
                  entry['sourceType']?.toString() ??
                  entry['type']?.toString() ??
                  'movimentacao';
              final dateLabel = _dateLabel(
                entry['createdAt'] ??
                    entry['created_at'] ??
                    entry['date'] ??
                    entry['occurredAt'],
              );

              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.performanceCardBorder),
                  boxShadow: AppShadows.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      isCredit
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      color: isCredit
                          ? AppColors.action500
                          : AppColors.missionsRewardGold,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _prettyType(type),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.brand900Variant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (dateLabel != null)
                            Text(
                              dateLabel,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${isCredit ? '+' : ''}$amount',
                      style: AppTextStyles.captionStrong.copyWith(
                        color: isCredit
                            ? AppColors.action500
                            : AppColors.missionsRewardGold,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  int _toInt(Object? value) {
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

  String _prettyType(String rawType) {
    final key = rawType.trim().toLowerCase();
    if (key == 'mission_reward') {
      return 'Recompensa de missão';
    }
    if (key == 'avatar_frame_purchase') {
      return 'Compra de moldura';
    }
    if (key == 'avatar_background_purchase') {
      return 'Compra de fundo';
    }
    if (key == 'offensive_blocker_purchase' ||
        key == 'offensive_blocker_auto_purchase') {
      return 'Compra de bloqueador';
    }
    if (key == 'streak_restore_purchase') {
      return 'Restauração de sequência';
    }
    if (key == 'blocker_purchase' || key == 'profile_blocker_purchase') {
      return 'Compra de bloqueador';
    }

    return rawType.replaceAll('_', ' ');
  }

  String? _dateLabel(Object? raw) {
    final value = raw?.toString();
    if (value == null || value.isEmpty) {
      return null;
    }

    final date = DateTime.tryParse(value);
    if (date == null) {
      return value;
    }

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
