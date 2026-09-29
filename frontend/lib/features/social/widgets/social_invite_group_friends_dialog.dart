import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/or_divider.dart';
import '../models/social_group_models.dart';
import 'social_friend_list_item.dart';

class SocialInviteGroupFriendsDialog extends StatefulWidget {
  const SocialInviteGroupFriendsDialog({
    super.key,
    required this.friends,
    required this.excludedUserIds,
    required this.onShareLink,
    required this.onCopyId,
  });

  final List<SocialFriend> friends;
  final Set<String> excludedUserIds;
  final VoidCallback onShareLink;
  final VoidCallback onCopyId;

  @override
  State<SocialInviteGroupFriendsDialog> createState() => _SocialInviteGroupFriendsDialogState();
}

class _SocialInviteGroupFriendsDialogState extends State<SocialInviteGroupFriendsDialog> {
  final Set<String> _selectedFriendIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final availableFriends = widget.friends
        .where((friend) => !widget.excludedUserIds.contains(friend.id))
        .toList(growable: false);
    final selectedCount = _selectedFriendIds.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.performanceCardBorder, width: 2),
          boxShadow: AppShadows.performanceCard,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Convidar amigos',
                    style: AppTextStyles.missionsSectionTitle.copyWith(
                      color: AppColors.brand900Variant,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              'Selecione amigos para adicionar ao grupo.',
              style: AppTextStyles.captionStrong.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (availableFriends.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'Nenhum amigo disponível para convidar.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: availableFriends.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final friend = availableFriends[index];
                    final isSelected = _selectedFriendIds.contains(friend.id);
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedFriendIds.remove(friend.id);
                            } else {
                              _selectedFriendIds.add(friend.id);
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.missionsXpPill.withValues(alpha: 0.45)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.action500
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: SocialFriendListItem(friend: friend),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: selectedCount > 0
                  ? (selectedCount == 1
                        ? 'Adicionar 1 amigo'
                        : 'Adicionar $selectedCount amigos')
                  : 'Selecionar amigos',
              onPressed: selectedCount > 0
                  ? () => Navigator.of(context).pop(_selectedFriendIds.toList(growable: false))
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            const OrDivider(),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Compartilhar link',
                    variant: AppButtonVariant.outline,
                    leadingIcon: Icons.share_rounded,
                    onPressed: widget.onShareLink,
                    textStyle: AppTextStyles.buttonMedium.copyWith(fontSize: 13),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Copiar ID',
                    variant: AppButtonVariant.outline,
                    leadingIcon: Icons.content_copy_rounded,
                    onPressed: widget.onCopyId,
                    textStyle: AppTextStyles.buttonMedium.copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
