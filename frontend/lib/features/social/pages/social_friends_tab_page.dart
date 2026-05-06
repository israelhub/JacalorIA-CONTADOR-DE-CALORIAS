import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../models/social_group_models.dart';
import '../widgets/social_empty_state.dart';
import '../widgets/social_friend_list_item.dart';

class SocialFriendsTabPage extends StatelessWidget {
  const SocialFriendsTabPage({
    super.key,
    required this.friends,
    required this.onAddFriend,
    required this.onOpenFriendProfile,
  });

  final List<SocialFriend> friends;
  final VoidCallback onAddFriend;
  final ValueChanged<SocialFriend> onOpenFriendProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppButton(
          label: 'Adicionar amigo',
          variant: AppButtonVariant.outline,
          leadingIcon: Icons.person_add_alt_1_rounded,
          onPressed: onAddFriend,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSectionHeader(
          title: 'Seus amigos',
          titleStyle: AppTextStyles.missionsSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (friends.isEmpty)
          const SocialEmptyState(
            icon: Icons.people_alt_outlined,
            title: 'Nenhum amigo ainda',
            subtitle: 'Adicione amigos por e-mail ou link para começar.',
          )
        else
          Column(
            children: [
              for (final friend in friends) ...[
                SocialFriendListItem(
                  friend: friend,
                  onTap: () => onOpenFriendProfile(friend),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
      ],
    );
  }
}
