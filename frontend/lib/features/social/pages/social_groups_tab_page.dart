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
    required this.groups,
    required this.onCreateGroup,
    required this.onJoinGroup,
    required this.onOpenGroup,
  });

  final List<SocialGroupSummary> groups;
  final VoidCallback onCreateGroup;
  final VoidCallback onJoinGroup;
  final ValueChanged<String> onOpenGroup;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppButton(
          label: 'Criar novo',
          leadingIcon: Icons.add_rounded,
          onPressed: onCreateGroup,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Entrar em grupo',
          variant: AppButtonVariant.outline,
          leadingIcon: Icons.login_rounded,
          onPressed: onJoinGroup,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSectionHeader(
          title: 'Seus grupos',
          titleStyle: AppTextStyles.missionsSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (groups.isEmpty)
          const SocialEmptyState(
            icon: Icons.groups_2_rounded,
            title: 'Nenhum grupo por aqui ainda',
            subtitle: 'Crie ou entre por link para disputar com seus amigos.',
          )
        else
          Column(
            children: [
              for (final group in groups) ...[
                SocialGroupCard(group: group, onTap: () => onOpenGroup(group.id)),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
      ],
    );
  }
}
