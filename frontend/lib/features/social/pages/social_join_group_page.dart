import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../models/social_group_models.dart';
import 'social_public_groups_page.dart';

class SocialJoinGroupPage extends StatefulWidget {
  const SocialJoinGroupPage({
    super.key,
    required this.fetchPublicGroups,
  });

  final Future<List<SocialGroupSummary>> Function({
    required String query,
    int? durationDays,
    String? competitionType,
  }) fetchPublicGroups;

  @override
  State<SocialJoinGroupPage> createState() => _SocialJoinGroupPageState();
}

class _SocialJoinGroupPageState extends State<SocialJoinGroupPage> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _openPublicGroups() async {
    final selectedGroupId = await context.pushSlidePage<String>(
      SocialPublicGroupsPage(fetchGroups: widget.fetchPublicGroups),
    );
    if (!mounted || selectedGroupId == null || selectedGroupId.trim().isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      SocialJoinGroupDialogResult.byPublicGroupId(selectedGroupId.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.brand900Variant,
        title: Text(
          'Entrar',
          style: AppTextStyles.missionsSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Insira um código de convite ou encontre grupos públicos para participar.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppInputField(
                label: 'Código do grupo',
                hint: 'Ex: ABCD-1234',
                controller: _codeController,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Ver grupos públicos',
                variant: AppButtonVariant.outline,
                onPressed: _openPublicGroups,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Entrar',
                onPressed: () => Navigator.of(context).pop(
                  SocialJoinGroupDialogResult.byCode(_codeController.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SocialJoinGroupDialogResult {
  const SocialJoinGroupDialogResult._({
    this.code,
    this.publicGroupId,
    required this.openPublicGroups,
  });

  const SocialJoinGroupDialogResult.byCode(String code)
      : this._(code: code, openPublicGroups: false);

  const SocialJoinGroupDialogResult.byPublicGroupId(String publicGroupId)
      : this._(publicGroupId: publicGroupId, openPublicGroups: false);

  const SocialJoinGroupDialogResult.openPublicGroups()
      : this._(openPublicGroups: true);

  final String? code;
  final String? publicGroupId;
  final bool openPublicGroups;
}
