import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/framed_avatar.dart';

class SocialProfileInviteCard extends StatelessWidget {
  const SocialProfileInviteCard({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.avatarFrameId,
    required this.onCopyId,
  });

  final String name;
  final String? avatarUrl;
  final String? avatarFrameId;
  final VoidCallback onCopyId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.performanceCardBorder),
      ),
      child: Row(
        children: [
          FramedAvatar(
            size: 48,
            avatarUrl: avatarUrl,
            frameId: avatarFrameId,
            fallbackText: name,
            backgroundColor: AppColors.surface,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: AppTextStyles.homeMealTitle.copyWith(
                      color: AppColors.brand900Variant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: onCopyId,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copiar ID'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
