import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/jaca_emoji_catalog.dart';

class JacaEmojiPicker extends StatelessWidget {
  const JacaEmojiPicker({
    super.key,
    required this.onSelected,
    this.ownedIds = const <String>{},
  });

  final ValueChanged<JacaEmojiItem> onSelected;
  final Set<String> ownedIds;

  static const int _columns = 5;
  static const double _gap = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final visible = JacaEmojiCatalog.visibleItems(ownedIds);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(
          top: BorderSide(color: AppColors.performanceCardBorder),
        ),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: visible.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _columns,
          crossAxisSpacing: _gap,
          mainAxisSpacing: _gap,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final emoji = visible[index];
          return Semantics(
            button: true,
            label: emoji.label,
            child: InkWell(
              key: ValueKey('jaca-emoji-${emoji.id}'),
              onTap: () => onSelected(emoji),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.asset(
                emoji.assetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          );
        },
      ),
    );
  }
}
