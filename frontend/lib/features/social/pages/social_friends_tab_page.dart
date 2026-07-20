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
            if (pendingRequestCount > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              _PendingFriendRequestsFloatingButton(
                pendingCount: pendingRequestCount,
                onPressed: onOpenRequests,
              ),
            ],
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

class _PendingFriendRequestsFloatingButton extends StatelessWidget {
  const _PendingFriendRequestsFloatingButton({
    required this.pendingCount,
    required this.onPressed,
  });

  final int pendingCount;
  final VoidCallback onPressed;

  String get _countLabel => pendingCount > 99 ? '99+' : pendingCount.toString();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('friend-requests-button'),
      button: true,
      label: 'Abrir solicitações de amizade, $pendingCount pendentes',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onPressed,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.accent500,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.brand900Variant.withValues(alpha: 0.12)),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.action500Shadow,
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: AppColors.brand900Variant,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brand900Variant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _countLabel,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.captionStrong.copyWith(
                      color: AppColors.surface,
                      height: 1,
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
