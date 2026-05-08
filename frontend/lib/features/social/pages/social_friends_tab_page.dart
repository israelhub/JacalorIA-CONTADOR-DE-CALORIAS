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
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Adicionar amigo',
                variant: AppButtonVariant.outline,
                leadingIcon: Icons.person_add_alt_1_rounded,
                onPressed: onAddFriend,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FriendRequestBellButton(
              pendingCount: pendingRequestCount,
              onPressed: onOpenRequests,
            ),
          ],
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

class _FriendRequestBellButton extends StatelessWidget {
  const _FriendRequestBellButton({
    required this.pendingCount,
    required this.onPressed,
  });

  final int pendingCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('friend-requests-button'),
      button: true,
      label: pendingCount > 0
          ? 'Abrir solicitações de amizade, $pendingCount pendentes'
          : 'Abrir solicitações de amizade',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.borderAlt),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowButtonAlt,
                        offset: Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.action500,
                    size: 20,
                  ),
                ),
                if (pendingCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accent500,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        pendingCount > 99 ? '99+' : pendingCount.toString(),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.captionStrong.copyWith(
                          color: AppColors.brand900Variant,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
