import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../avatar_frames/pages/avatar_frame_store_page.dart';
import '../../auth/service/auth_service.dart';
import '../../home/widgets/home_weight_quick_edit_button.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_guide_card.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../../shared/widgets/app_refresh_scroll_view.dart';
import '../../../shared/widgets/app_scroll_reveal.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../../shared/widgets/app_toast.dart';
import '../models/missions_overview.dart';
import '../services/missions_service.dart';
import '../widgets/check_in_rewards_card.dart';
import '../widgets/mission_card.dart';
import '../widgets/missions_hero_header.dart';

class MissionsPage extends StatefulWidget {
  const MissionsPage({
    super.key,
    MissionsService? service,
    this.authService,
    this.refreshVersion = 0,
  }) : _service = service ?? const MissionsService();

  final MissionsService _service;
  final AuthService? authService;
  final int refreshVersion;

  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage>
    with AutomaticKeepAliveClientMixin {
  static const String _hideIntroLocalKey = 'missions_hide_intro_local';
  MissionsOverview? _overview;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _showIntro = true;
  bool _isClaimingCheckIn = false;
  String? _errorMessage;
  final _weightController = HomeWeightQuickEditController();

  @override
  bool get wantKeepAlive => true;

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
    if (!silent || !hadData) {
      final nextLoading = !hadData;
      if (_isLoading != nextLoading || _errorMessage != null) {
        setState(() {
          // Only show the blocking loader when there is no cached content yet.
          _isLoading = nextLoading;
          _errorMessage = null;
        });
      }
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
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: <Widget>[
          _buildContent(),
          Positioned(
            width: 1,
            height: 1,
            right: 0,
            bottom: 0,
            child: HomeWeightQuickEditButton(
              userProfile: _profile,
              authService: widget.authService,
              controller: _weightController,
              showTrigger: false,
              onWeightUpdated: _onWeightUpdated,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const _MissionsBodySkeleton();
    }

    if (_errorMessage != null || _overview == null) {
      return SafeArea(
        child: Center(
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
        ),
      );
    }

    final overview = _overview!;
    final weekendEvent = overview.weekendEvent;
    final weekendSections = overview.sections
        .where((section) => section.id == MissionType.weekend)
        .toList(growable: false);
    final weekendSection = weekendSections.isEmpty
        ? null
        : weekendSections.first;
    final regularSections = overview.sections
        .where((section) => section.id != MissionType.weekend)
        .toList(growable: false);
    final showWeekendSection = weekendEvent.active && weekendSection != null;
    final bottomInset = homeShellScrollBottomInset(context);

    return AppRefreshScrollView(
      onRefresh: () => _loadMissions(silent: true),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MissionsHeroHeader(
            gold: overview.gold,
            xp: overview.xp,
            onOpenStore: _openStore,
            onOpenGoldStatement: _openGoldStatement,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              bottomInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (overview.checkIn.active) ...<Widget>[
                  AppScrollReveal(
                    child: CheckInRewardsCard(
                      checkIn: overview.checkIn,
                      isClaiming: _isClaimingCheckIn,
                      onClaim: overview.checkIn.canClaimToday
                          ? _claimCheckIn
                          : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (_showIntro) ...<Widget>[
                  AppScrollReveal(
                    delay: const Duration(milliseconds: 60),
                    child: AppGuideCard(
                      title: overview.introTitle,
                      description: overview.introDescription,
                      icon: Icons.campaign_rounded,
                      backgroundColor: AppColors.action500,
                      iconBackgroundColor: AppColors.missionsIntroIcon,
                      iconColor: AppColors.surface,
                      titleStyle: AppTextStyles.missionsIntroTitle.copyWith(
                        color: AppColors.surface,
                      ),
                      descriptionStyle: AppTextStyles.missionsIntroDescription
                          .copyWith(color: AppColors.surface),
                      onClose: () {
                        setState(() {
                          _showIntro = false;
                        });
                        _persistGuidePreference();
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (showWeekendSection) ...<Widget>[
                  AppScrollReveal(
                    child: AppSectionHeader(
                      title: weekendSection.title,
                      subtitle: weekendSection.subtitle,
                      subtitleIcon: Icons.schedule_rounded,
                      titleStyle: AppTextStyles.missionsSectionTitle.copyWith(
                        color: AppColors.brand900Variant,
                      ),
                      subtitleColor: AppColors.socialMetricStreak,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ..._buildMissionCards(
                    _sortedMissions(weekendSection.missions),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
                for (
                  var sectionIndex = 0;
                  sectionIndex < regularSections.length;
                  sectionIndex += 1
                ) ...<Widget>[
                  AppScrollReveal(
                    child: AppSectionHeader(
                      title: regularSections[sectionIndex].title,
                      subtitle: regularSections[sectionIndex].subtitle,
                      subtitleIcon: Icons.schedule_rounded,
                      titleStyle: AppTextStyles.missionsSectionTitle.copyWith(
                        color: AppColors.brand900Variant,
                      ),
                      subtitleColor: AppColors.socialMetricStreak,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ..._buildMissionCards(
                    _sortedMissions(regularSections[sectionIndex].missions),
                  ),
                  if (sectionIndex < regularSections.length - 1)
                    const SizedBox(height: AppSpacing.xxxl),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMissionCards(List<MissionItem> missions) {
    final widgets = <Widget>[];
    for (var index = 0; index < missions.length; index += 1) {
      final mission = missions[index];
      widgets.add(
        AppScrollReveal(
          delay: Duration(milliseconds: (index * 50).clamp(0, 150)),
          child: MissionCard(
            mission: mission,
            onTap:
                mission.key == weeklyUpdateWeightMissionKey &&
                    !mission.isCompleted
                ? _weightController.open
                : null,
          ),
        ),
      );
      if (index < missions.length - 1) {
        widgets.add(const SizedBox(height: AppSpacing.md));
      }
    }
    return widgets;
  }

  void _onWeightUpdated(Map<String, dynamic> updated) {
    setState(() {
      _profile = <String, dynamic>{...?_profile, ...updated};
    });
    _loadMissions(silent: true);
  }

  Future<void> _claimCheckIn() async {
    if (_isClaimingCheckIn) {
      return;
    }

    setState(() {
      _isClaimingCheckIn = true;
    });

    try {
      final result = await widget._service.claimCheckIn();
      if (!mounted) {
        return;
      }

      final checkInJson =
          result['checkIn'] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      final summary =
          result['summary'] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      final rewardSummary = result['rewardSummary']?.toString();
      final overview = _overview;

      if (overview != null) {
        setState(() {
          _overview = overview.copyWith(
            gold: _asInt(summary['gold'], fallback: overview.gold),
            xp: _asInt(summary['xp'], fallback: overview.xp),
            goldLifetimeEarned: _asInt(
              summary['goldLifetimeEarned'],
              fallback: overview.goldLifetimeEarned,
            ),
            goldLifetimeSpent: _asInt(
              summary['goldLifetimeSpent'],
              fallback: overview.goldLifetimeSpent,
            ),
            xpLifetimeEarned: _asInt(
              summary['xpLifetimeEarned'],
              fallback: overview.xpLifetimeEarned,
            ),
            xpLifetimeSpent: _asInt(
              summary['xpLifetimeSpent'],
              fallback: overview.xpLifetimeSpent,
            ),
            checkIn: CheckInInfo.fromJson(checkInJson),
          );
          _isClaimingCheckIn = false;
        });
      } else {
        setState(() {
          _isClaimingCheckIn = false;
        });
        await _loadMissions(silent: true);
      }

      if (!mounted) {
        return;
      }
      AppToast.success(
        context,
        message: rewardSummary == null || rewardSummary.isEmpty
            ? 'Recompensa de check-in recebida!'
            : 'Você ganhou: $rewardSummary',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isClaimingCheckIn = false;
      });
      AppToast.error(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  int _asInt(Object? value, {required int fallback}) {
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

    final changed = await context.pushAppearPage<Object>(
      AvatarFrameStorePage(
        initialGoldBalance: overview.gold,
        initialGoldLifetimeEarned: overview.goldLifetimeEarned,
        initialGoldLifetimeSpent: overview.goldLifetimeSpent,
        profile: profile,
        authService: widget.authService,
      ),
    );

    if (!mounted) {
      return;
    }
    if (changed == 'go_to_missions') {
      return;
    }
    if (changed == true) {
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

class _GoldStatementPage extends StatefulWidget {
  const _GoldStatementPage({required this.service});

  final MissionsService service;

  @override
  State<_GoldStatementPage> createState() => _GoldStatementPageState();
}

class _GoldStatementPageState extends State<_GoldStatementPage> {
  late final Future<List<Map<String, dynamic>>> _statementFuture;

  @override
  void initState() {
    super.initState();
    // Cria o future uma única vez; senão qualquer rebuild refaz o request.
    _statementFuture = widget.service.fetchGoldStatement();
  }

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
        future: _statementFuture,
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
    if (key == 'check_in_reward') {
      return 'Recompensa de check-in';
    }
    if (key == 'avatar_frame_purchase') {
      return 'Compra de moldura';
    }
    if (key == 'avatar_background_purchase') {
      return 'Compra de fundo';
    }
    if (key == 'jaca_emoji_purchase') {
      return 'Compra de figurinha';
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

class _MissionsBodySkeleton extends StatelessWidget {
  const _MissionsBodySkeleton();

  @override
  Widget build(BuildContext context) {
    final bottomInset = homeShellScrollBottomInset(context);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _MissionsHeroHeaderSkeleton(),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              bottomInset,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _CheckInRewardsSkeleton(),
                SizedBox(height: AppSpacing.lg),
                _MissionSectionSkeleton(cardCount: 3),
                SizedBox(height: AppSpacing.xxxl),
                _MissionSectionSkeleton(cardCount: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionsHeroHeaderSkeleton extends StatelessWidget {
  const _MissionsHeroHeaderSkeleton();

  static const Color _bone = Color.fromRGBO(25, 54, 41, 0.12);
  static const Color _boneHighlight = Color.fromRGBO(25, 54, 41, 0.22);

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22, topInset + 16, 12, 26),
      decoration: const BoxDecoration(
        color: AppColors.brand300,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppSkeletonBox(
                    height: 28,
                    width: 140,
                    color: _bone,
                    highlightColor: _boneHighlight,
                  ),
                ),
              ),
              AppSkeletonBox(
                height: 32,
                width: 64,
                borderRadius: AppRadius.pill,
                color: _bone,
                highlightColor: _boneHighlight,
              ),
              SizedBox(width: 4),
              AppSkeletonBox(
                height: 32,
                width: 64,
                borderRadius: AppRadius.pill,
                color: _bone,
                highlightColor: _boneHighlight,
              ),
            ],
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppSkeletonBox(
                  height: 24,
                  color: _bone,
                  highlightColor: _boneHighlight,
                ),
                SizedBox(height: 8),
                AppSkeletonBox(
                  height: 24,
                  width: 220,
                  color: _bone,
                  highlightColor: _boneHighlight,
                ),
              ],
            ),
          ),
          SizedBox(height: 22),
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: AppSkeletonBox(
              height: 52,
              borderRadius: AppRadius.pill,
              color: _bone,
              highlightColor: _boneHighlight,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckInRewardsSkeleton extends StatelessWidget {
  const _CheckInRewardsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppSkeletonBox(height: 22, width: 180),
        SizedBox(height: AppSpacing.md),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.all(Radius.circular(20)),
            border: Border.fromBorderSide(
              BorderSide(color: AppColors.performanceCardBorder, width: 2),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 18, 0, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: AppSkeletonBox(height: 16, width: 240),
                ),
                SizedBox(height: AppSpacing.xl),
                SizedBox(
                  height: 76,
                  child: ListView.separated(
                    physics: NeverScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: 4,
                    separatorBuilder: (_, __) => SizedBox(width: 6),
                    itemBuilder: (_, __) => _CheckInDaySkeleton(),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: AppSkeletonBox(height: 48, borderRadius: AppRadius.md),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckInDaySkeleton extends StatelessWidget {
  const _CheckInDaySkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 86,
      child: Column(
        children: <Widget>[
          AppSkeletonBox(width: 54, height: 54, borderRadius: 12),
          SizedBox(height: 6),
          AppSkeletonBox(width: 48, height: 12, borderRadius: AppRadius.sm),
        ],
      ),
    );
  }
}

class _MissionSectionSkeleton extends StatelessWidget {
  const _MissionSectionSkeleton({this.cardCount = 3});

  final int cardCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Row(
          children: <Widget>[
            AppSkeletonBox(height: 22, width: 160),
            Spacer(),
            AppSkeletonBox(height: 14, width: 88),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var index = 0; index < cardCount; index += 1) ...<Widget>[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          const _MissionCardSkeleton(),
        ],
      ],
    );
  }
}

class _MissionCardSkeleton extends StatelessWidget {
  const _MissionCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.performanceCardBorder, width: 1.5),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppSkeletonBox(height: 18, width: 220),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: AppSkeletonBox(height: 22, borderRadius: AppRadius.pill),
              ),
              SizedBox(width: 10),
              AppSkeletonBox(width: 52, height: 16, borderRadius: AppRadius.sm),
              SizedBox(width: 6),
              AppSkeletonBox(width: 52, height: 16, borderRadius: AppRadius.sm),
            ],
          ),
        ],
      ),
    );
  }
}
