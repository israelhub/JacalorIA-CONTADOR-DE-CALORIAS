import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../social/models/jaca_emoji_catalog.dart';

Future<String?> showProfileReactionEmojiSheet({
  required BuildContext context,
  required Set<String> ownedIds,
  String? selectedId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (context) {
      final visible = JacaEmojiCatalog.visibleItems(ownedIds);

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Reação do perfil',
                textAlign: TextAlign.center,
                style: AppTextStyles.missionsTitle.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Escolha um emoji para aparecer na sua foto',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visible.length + 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isSelected =
                        selectedId == null || selectedId.trim().isEmpty;
                    return _ReactionTile(
                      key: const ValueKey('profile-reaction-none'),
                      selected: isSelected,
                      onTap: () => Navigator.of(context).pop(''),
                      child: Icon(
                        Icons.emoji_emotions_outlined,
                        size: 28,
                        color: AppColors.textSecondary,
                      ),
                    );
                  }

                  final emoji = visible[index - 1];
                  final isSelected = selectedId == emoji.id;
                  return _ReactionTile(
                    key: ValueKey('profile-reaction-${emoji.id}'),
                    selected: isSelected,
                    onTap: () => Navigator.of(context).pop(emoji.id),
                    child: Image.asset(
                      emoji.assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ReactionTile extends StatelessWidget {
  const _ReactionTile({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.missionsXpPill : AppColors.insetSurface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected
                  ? AppColors.action500
                  : AppColors.performanceCardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: child,
          ),
        ),
      ),
    );
  }
}
