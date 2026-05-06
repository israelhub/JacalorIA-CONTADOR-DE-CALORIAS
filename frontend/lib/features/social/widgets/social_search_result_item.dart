import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/social_group_models.dart';

class SocialSearchResultItem extends StatelessWidget {
  const SocialSearchResultItem({super.key, required this.user, required this.onAdd});

  final SocialUserSearchResult user;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surface,
            backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: AppTextStyles.captionStrong.copyWith(
                      color: AppColors.brand900Variant,
                    ),
                  )
                : null,
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
          else
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
              label: const Text('Adicionar'),
            ),
        ],
      ),
    );
  }
}
