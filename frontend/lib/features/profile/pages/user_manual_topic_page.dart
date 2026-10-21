import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_ambient_page_glow.dart';
import '../../../shared/widgets/app_back_page_header.dart';
import '../../home/widgets/home_shell_layout.dart';
import '../helpers/user_manual_content.dart';
import '../widgets/profile_section_card.dart';

class UserManualTopicPage extends StatelessWidget {
  const UserManualTopicPage({super.key, required this.topic});

  final UserManualTopic topic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBackPageHeader(
        title: topic.title,
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      topic.icon,
                      color: AppColors.brand900Variant,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic.subtitle,
                            style: AppTextStyles.missionsSectionTitle.copyWith(
                              color: AppColors.brand900Variant,
                            ),
                          ),
                          if (topic.coveredInInitialTour) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Também aparece no tour inicial.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.action500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.cardGap),
              for (final section in topic.sections) ...[
                ProfileSectionCard(
                  title: section.title,
                  child: Text(
                    section.body,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.cardGap),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
