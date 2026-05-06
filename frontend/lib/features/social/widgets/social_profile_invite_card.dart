import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class SocialProfileInviteCard extends StatelessWidget {
  const SocialProfileInviteCard({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.onCopyId,
  });

  final String name;
  final String? avatarUrl;
  final VoidCallback onCopyId;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveAvatarUrl(avatarUrl);
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
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surface,
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
            child: imageUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: AppTextStyles.homeMealTitle.copyWith(
                      color: AppColors.brand900Variant,
                    ),
                  )
                : null,
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

  String? _resolveAvatarUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;
    return null;
  }
}
