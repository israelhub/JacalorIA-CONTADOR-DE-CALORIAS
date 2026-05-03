import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_dashed_action_button.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../../shared/widgets/app_guide_card.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../models/social_group_models.dart';
import '../services/social_service.dart';
import '../widgets/social_create_group_sheet.dart';
import '../widgets/social_group_card.dart';
import 'social_group_detail_page.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key, SocialService? service})
    : _service = service ?? const SocialService();

  final SocialService _service;

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  final List<SocialGroupSummary> _groups = <SocialGroupSummary>[];
  bool _isLoading = true;
  bool _showIntro = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final groups = await widget._service.fetchGroups();
      if (!mounted) {
        return;
      }

      setState(() {
        _groups
          ..clear()
          ..addAll(groups);
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

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage ?? 'Não foi possível carregar os grupos.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: 'Tentar novamente', onPressed: _loadGroups),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Social',
                  style: AppTextStyles.missionsTitle.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
              ),
              const Icon(
                Icons.groups_2_rounded,
                size: 28,
                color: AppColors.brand900Variant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_showIntro) ...[
            AppGuideCard(
              title: 'Conte calorias com seus amigos',
              description:
                  'Crie grupos, convide amigos e veja quem mantém a meta calórica diária.',
              icon: Icons.emoji_events_rounded,
              onClose: () {
                setState(() {
                  _showIntro = false;
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppDashedActionButton(
            label: 'Criar novo grupo',
            onTap: _openCreateGroupSheet,
            borderRadius: AppRadius.md + 2,
            height: 52,
            labelStyle: AppTextStyles.homeAction.copyWith(
              color: AppColors.action500,
            ),
            leading: const Icon(
              Icons.add_rounded,
              color: AppColors.action500,
              size: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(
            title: 'Seus grupos',
            titleStyle: AppTextStyles.missionsSectionTitle.copyWith(
              color: AppColors.brand900Variant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_groups.isEmpty)
            const _EmptyGroupsState()
          else
            Column(
              children: [
                for (final group in _groups) ...[
                  SocialGroupCard(
                    group: group,
                    onTap: () => _openGroupDetail(group.id),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _openCreateGroupSheet() async {
    final result = await showModalBottomSheet<SocialGroupDetail>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SocialCreateGroupSheet(service: widget._service),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _groups.insert(0, result.group);
    });

    await context.pushSlidePage(
      SocialGroupDetailPage(groupId: result.group.id, initialDetail: result),
    );

    if (mounted) {
      await _loadGroups();
    }
  }

  Future<void> _openGroupDetail(String groupId) async {
    await context.pushSlidePage(SocialGroupDetailPage(groupId: groupId));

    if (mounted) {
      await _loadGroups();
    }
  }
}

class _EmptyGroupsState extends StatelessWidget {
  const _EmptyGroupsState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.performanceCardBorder,
              width: 2,
            ),
            boxShadow: AppShadows.performanceCard,
          ),
          child: Column(
            children: [
              const Icon(
                Icons.groups_2_rounded,
                size: 36,
                color: AppColors.action500,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Nenhum grupo por aqui ainda.',
                textAlign: TextAlign.center,
                style: AppTextStyles.homeMealTitle.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Crie seu primeiro grupo para convidar amigos e acompanhar o ranking.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
