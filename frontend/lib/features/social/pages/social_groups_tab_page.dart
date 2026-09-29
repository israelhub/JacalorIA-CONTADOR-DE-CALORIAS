import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../models/social_group_models.dart';
import '../widgets/social_empty_state.dart';
import '../widgets/social_group_card.dart';

class SocialGroupsTabPage extends StatelessWidget {
  const SocialGroupsTabPage({
    super.key,
    required this.activeGroups,
    required this.historyGroups,
    required this.isGroupFinished,
    required this.onCreateGroup,
    required this.onJoinGroup,
    required this.onOpenGroup,
  });

  final List<SocialGroupSummary> activeGroups;
  final List<SocialGroupSummary> historyGroups;
  final bool Function(SocialGroupSummary group) isGroupFinished;
  final VoidCallback onCreateGroup;
  final VoidCallback onJoinGroup;
  final ValueChanged<String> onOpenGroup;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Criar novo',
                leadingIcon: Icons.add_rounded,
                onPressed: onCreateGroup,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: 'Entrar',
                variant: AppButtonVariant.outline,
                leadingIcon: Icons.login_rounded,
                onPressed: onJoinGroup,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSectionHeader(
          title: 'Seus grupos ativos',
          titleStyle: AppTextStyles.missionsSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (activeGroups.isEmpty)
          const SocialEmptyState(
            icon: Icons.groups_2_rounded,
            title: 'Nenhum grupo por aqui ainda',
            subtitle: 'Crie ou entre por link para disputar com seus amigos.',
          )
        else
          Column(
            children: [
              for (final group in activeGroups) ...[
                SocialGroupCard(
                  group: group,
                  isFinished: isGroupFinished(group),
                  onTap: () => onOpenGroup(group.id),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        if (historyGroups.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(
            title: 'Histórico de grupos',
            titleStyle: AppTextStyles.missionsSectionTitle.copyWith(
              color: AppColors.brand900Variant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Column(
            children: [
              for (final group in historyGroups) ...[
                SocialGroupCard(
                  group: group,
                  isFinished: true,
                  onTap: () => onOpenGroup(group.id),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
