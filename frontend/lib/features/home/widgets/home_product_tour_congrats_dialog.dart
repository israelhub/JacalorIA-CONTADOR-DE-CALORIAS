import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../helpers/home_shell_product_tour_rewards.dart';

class HomeProductTourCongratsDialog extends StatelessWidget {
  const HomeProductTourCongratsDialog({super.key});

  static const imageAsset = 'assets/images/jaca_tutorial_congrats.png';

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const HomeProductTourCongratsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textSecondary,
    );
    final linkStyle = bodyStyle.copyWith(
      color: AppColors.action500,
      fontWeight: FontWeight.w700,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.performanceCardBorder, width: 2),
          boxShadow: AppShadows.performanceCard,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                imageAsset,
                height: 148,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Parabéns por concluir o tutorial!',
                textAlign: TextAlign.center,
                style: AppTextStyles.missionsSectionTitle.copyWith(
                  color: AppColors.brand900Variant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text.rich(
                TextSpan(
                  style: bodyStyle,
                  children: [
                    const TextSpan(
                      text:
                          'Agora é hora de explorar o JacalorIA no seu ritmo.\n\nSe ficar com alguma dúvida, vá em ',
                    ),
                    TextSpan(text: 'Perfil', style: linkStyle),
                    const TextSpan(text: ' > '),
                    TextSpan(text: 'Manual do usuário', style: linkStyle),
                    const TextSpan(
                      text:
                          ': lá você também pode refazer este tutorial e encontrar outros.\n\nPor ter concluído o tutorial, você ganhou um emoji, uma moldura e um fundo que podem ser equipados através da loja.',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Row(
                children: [
                  Expanded(
                    child: _RewardPreviewCard(
                      assetPath: HomeShellProductTourRewards.emojiAsset,
                      previewStyle: _RewardPreviewStyle.sticker,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _RewardPreviewCard(
                      assetPath: HomeShellProductTourRewards.frameAsset,
                      previewStyle: _RewardPreviewStyle.frame,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _RewardPreviewCard(
                      assetPath: HomeShellProductTourRewards.backgroundAsset,
                      previewStyle: _RewardPreviewStyle.background,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Começar',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _RewardPreviewStyle { sticker, frame, background }

class _RewardPreviewCard extends StatelessWidget {
  const _RewardPreviewCard({
    required this.assetPath,
    required this.previewStyle,
  });

  final String assetPath;
  final _RewardPreviewStyle previewStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.insetSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: AspectRatio(
        aspectRatio: 1,
        child: _RewardPreviewImage(
          assetPath: assetPath,
          previewStyle: previewStyle,
        ),
      ),
    );
  }
}

class _RewardPreviewImage extends StatelessWidget {
  const _RewardPreviewImage({
    required this.assetPath,
    required this.previewStyle,
  });

  final String assetPath;
  final _RewardPreviewStyle previewStyle;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      assetPath,
      fit: switch (previewStyle) {
        _RewardPreviewStyle.background => BoxFit.cover,
        _RewardPreviewStyle.frame ||
        _RewardPreviewStyle.sticker => BoxFit.contain,
      },
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
    );

    return switch (previewStyle) {
      _RewardPreviewStyle.sticker => image,
      _RewardPreviewStyle.frame || _RewardPreviewStyle.background => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: image,
      ),
    };
  }
}
