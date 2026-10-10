import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../profile/widgets/profile_section_card.dart';
import '../models/social_group_models.dart';
import '../widgets/social_empty_state.dart';
import '../widgets/social_friend_list_item.dart';

class SocialFriendsTabPage extends StatelessWidget {
  const SocialFriendsTabPage({
    super.key,
    required this.friends,
    required this.onAddFriend,
    required this.pendingRequestCount,
    required this.onOpenRequests,
    required this.onOpenFriendProfile,
  });

  final List<SocialFriend> friends;
  final VoidCallback onAddFriend;
  final int pendingRequestCount;
  final VoidCallback onOpenRequests;
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
        ProfileSectionCard(
          title: 'Seus amigos',
          child: friends.isEmpty
              ? const SocialEmptyState(
                  icon: Icons.people_alt_outlined,
                  title: 'Nenhum amigo ainda',
                  subtitle:
                      'Adicione amigos por e-mail ou link para começar.',
                  backgroundColor: AppColors.insetSurface,
                )
              : Column(
                  children: [
                    for (var index = 0; index < friends.length; index++) ...[
                      if (index > 0) const SizedBox(height: AppSpacing.md),
                      SocialFriendListItem(
                        friend: friends[index],
                        backgroundColor: AppColors.insetSurface,
                        onTap: () => onOpenFriendProfile(friends[index]),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
