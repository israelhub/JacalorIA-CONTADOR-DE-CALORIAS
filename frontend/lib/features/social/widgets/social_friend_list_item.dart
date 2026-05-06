import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/social_group_models.dart';

class SocialFriendListItem extends StatelessWidget {
  const SocialFriendListItem({super.key, required this.friend, this.onTap});

  final SocialFriend friend;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveAvatarUrl(friend.avatarUrl);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.performanceCardBorder, width: 2),
            boxShadow: AppShadows.performanceCard,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceAlt,
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                child: imageUrl == null
                    ? Text(
                        friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                        style: AppTextStyles.homeMealTitle.copyWith(
                          color: AppColors.brand900Variant,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        friend.name,
                        style: AppTextStyles.homeMealTitle.copyWith(
                          color: AppColors.brand900Variant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 18,
                      color: AppColors.missionsRewardGold,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${friend.streakDays}',
                      style: AppTextStyles.homeMealTitle.copyWith(
                        color: AppColors.missionsRewardGold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _resolveAvatarUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final value = raw.trim();
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) {
      return value;
    }

    return null;
  }
}
