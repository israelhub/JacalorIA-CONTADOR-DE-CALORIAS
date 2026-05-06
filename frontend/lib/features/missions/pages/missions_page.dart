import 'package:flutter/material.dart';

import '../../auth/service/auth_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_guide_card.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../models/missions_overview.dart';
import '../services/missions_service.dart';
import '../widgets/mission_card.dart';

class MissionsPage extends StatefulWidget {
  const MissionsPage({super.key, MissionsService? service})
    : _service = service ?? const MissionsService();

  final MissionsService _service;

  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> {
  final AuthService _authService = AuthService();
  MissionsOverview? _overview;
  bool _isLoading = true;
  bool _showIntro = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMissions();
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

  Future<void> _loadMissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        widget._service.fetchMissions(),
        _authService.fetchProfile(),
      ]);
      if (!mounted) {
        return;
      }

      final result = results[0] as MissionsOverview;
      final profile = results[1] as Map<String, dynamic>;
      final hideGuideMe =
          profile['hideMissionsGuideMe'] == true || profile['hideGuideMe'] == true;

      setState(() {
        _overview = result;
        _showIntro = !hideGuideMe;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
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

    return SingleChildScrollView(
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
          for (final section in overview.sections) ...<Widget>[
            AppSectionHeader(
              title: section.title,
              subtitle: section.subtitle,
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final mission in _sortedMissions(section.missions)) ...<Widget>[
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
      await _authService.updateProfile(<String, dynamic>{
        'hideMissionsGuideMe': true,
      });
    } catch (_) {}
  }
}

class _CounterPill extends StatelessWidget {
  const _CounterPill({
    required this.value,
    required this.icon,
    required this.background,
  });

  final String value;
  final IconData icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
