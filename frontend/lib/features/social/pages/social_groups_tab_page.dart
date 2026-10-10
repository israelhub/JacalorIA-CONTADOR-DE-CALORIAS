import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../profile/widgets/profile_section_card.dart';
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
        ProfileSectionCard(
          title: 'Seus grupos ativos',
          child: activeGroups.isEmpty
              ? const SocialEmptyState(
                  icon: Icons.groups_2_rounded,
                  title: 'Nenhum grupo por aqui ainda',
                  subtitle:
                      'Crie ou entre por link para disputar com seus amigos.',
                  backgroundColor: AppColors.insetSurface,
                )
              : Column(
                  children: [
                    for (var index = 0; index < activeGroups.length; index++) ...[
                      if (index > 0) const SizedBox(height: AppSpacing.md),
                      SocialGroupCard(
                        group: activeGroups[index],
                        isFinished: isGroupFinished(activeGroups[index]),
                        backgroundColor: AppColors.insetSurface,
                        onTap: () => onOpenGroup(activeGroups[index].id),
                      ),
                    ],
                  ],
                ),
        ),
        if (historyGroups.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.cardGap),
          ProfileSectionCard(
            title: 'Histórico de grupos',
            child: Column(
              children: [
                for (var index = 0; index < historyGroups.length; index++) ...[
                  if (index > 0) const SizedBox(height: AppSpacing.md),
                  SocialGroupCard(
                    group: historyGroups[index],
                    isFinished: true,
                    backgroundColor: AppColors.insetSurface,
                    onTap: () => onOpenGroup(historyGroups[index].id),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
