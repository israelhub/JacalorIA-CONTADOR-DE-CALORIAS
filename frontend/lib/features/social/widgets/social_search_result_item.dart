import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/framed_avatar.dart';
import '../models/social_group_models.dart';

class SocialSearchResultItem extends StatelessWidget {
  const SocialSearchResultItem({super.key, required this.user, required this.onAdd});

  final SocialUserSearchResult user;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (user.friendRequestStatus) {
      'outgoing' => 'Solicitado',
      'incoming' => 'Solicitou você',
      _ => null,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          FramedAvatar(
            size: 40,
            avatarUrl: user.avatarUrl,
            frameId: user.avatarFrameId,
            fallbackText: user.name,
            backgroundColor: AppColors.surface,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: AppTextStyles.homeMealTitle.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
                Text(
                  user.email,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (user.isFriend)
            Text(
              'Já é amigo',
              style: AppTextStyles.captionStrong.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else if (statusLabel != null)
            Text(
              statusLabel,
              style: AppTextStyles.captionStrong.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.action500,
                textStyle: AppTextStyles.socialResultAction.copyWith(
                  color: AppColors.action500,
                ),
              ),
              onPressed: onAdd,
              icon: const Icon(
                Icons.person_add_alt_1_rounded,
                size: 16,
                color: AppColors.action500,
              ),
              label: const Text('Solicitar'),
            ),
        ],
      ),
    );
  }
}
