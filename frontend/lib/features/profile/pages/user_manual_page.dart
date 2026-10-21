import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_ambient_page_glow.dart';
import '../../../shared/widgets/app_back_page_header.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../home/pages/home_shell_page.dart';
import '../../home/widgets/home_shell_layout.dart';
import '../helpers/user_manual_content.dart';
import '../widgets/profile_section_card.dart';
import 'user_manual_topic_page.dart';

class UserManualPage extends StatelessWidget {
  const UserManualPage({super.key});

  Future<void> _startGuidedTour(
    BuildContext context,
    UserManualGuidedTourId id,
  ) async {
    final shell = HomeShellPage.controllerOf(context);
    if (shell == null) {
      AppToast.error(
        context,
        message:
            'Não foi possível iniciar o tour agora. Volte ao Início e tente de novo.',
      );
      return;
    }
    if (id == UserManualGuidedTourId.initial) {
      await shell.restartProductTour();
      return;
    }
    await shell.startManualGuidedTour(id);
  }

  Future<void> _openTopic(BuildContext context, UserManualTopic topic) {
    return context.pushSlidePage(UserManualTopicPage(topic: topic));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      extendBodyBehindAppBar: true,
      appBar: const AppBackPageHeader(
        title: 'Manual do usuário',
        backgroundColor: Colors.transparent,
      ),
      body: AppAmbientPageBody(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppBackPageHeader.scrollTopInset(context, extra: AppSpacing.lg),
            AppSpacing.lg,
            homeShellScrollBottomInset(context) + AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileSectionCard(
                title: 'Tutoriais guiados',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Um passo a passo curto na tela. Escolha uma área e a gente te mostra o caminho.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (var i = 0; i < userManualGuidedTours.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      _ManualTourTile(
                        entry: userManualGuidedTours[i],
                        onTap: () => _startGuidedTour(
                          context,
                          userManualGuidedTours[i].id,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.cardGap),
              ProfileSectionCard(
                title: 'Guias das páginas',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Textos didáticos de cada área do JacalorIA para consultar com calma.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (var i = 0; i < userManualTopics.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      _ManualTopicTile(
                        topic: userManualTopics[i],
                        onTap: () => _openTopic(context, userManualTopics[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualTourTile extends StatelessWidget {
  const _ManualTourTile({required this.entry, required this.onTap});

  final UserManualGuidedTourEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.pageBackground,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                alignment: Alignment.center,
                child: Icon(
                  entry.icon,
                  size: 20,
                  color: AppColors.brand900Variant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.play_circle_outline_rounded,
                color: AppColors.action500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManualTopicTile extends StatelessWidget {
  const _ManualTopicTile({required this.topic, required this.onTap});

  final UserManualTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.pageBackground,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                alignment: Alignment.center,
                child: Icon(
                  topic.icon,
                  size: 20,
                  color: AppColors.brand900Variant,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      topic.subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
