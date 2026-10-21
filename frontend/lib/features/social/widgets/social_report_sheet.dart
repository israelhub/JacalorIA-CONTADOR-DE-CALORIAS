import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

enum SocialReportReason { spam, harassment, inappropriate, other }

extension SocialReportReasonApi on SocialReportReason {
  String get apiValue {
    switch (this) {
      case SocialReportReason.spam:
        return 'spam';
      case SocialReportReason.harassment:
        return 'harassment';
      case SocialReportReason.inappropriate:
        return 'inappropriate';
      case SocialReportReason.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case SocialReportReason.spam:
        return 'Spam';
      case SocialReportReason.harassment:
        return 'Assédio ou bullying';
      case SocialReportReason.inappropriate:
        return 'Conteúdo impróprio';
      case SocialReportReason.other:
        return 'Outro';
    }
  }
}

class SocialReportResult {
  const SocialReportResult({required this.reason, this.details});

  final SocialReportReason reason;
  final String? details;
}

Future<SocialReportResult?> showSocialReportSheet(BuildContext context) {
  return showModalBottomSheet<SocialReportResult>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (context) => const _SocialReportSheet(),
  );
}

class _SocialReportSheet extends StatefulWidget {
  const _SocialReportSheet();

  @override
  State<_SocialReportSheet> createState() => _SocialReportSheetState();
}

class _SocialReportSheetState extends State<_SocialReportSheet> {
  SocialReportReason? _reason;
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.lg,
        AppSpacing.pageHorizontal,
        AppSpacing.lg + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Denunciar',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Escolha o motivo. Nossa equipe analisa denúncias.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final reason in SocialReportReason.values) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _reason = reason),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: _reason == reason
                        ? AppColors.insetSurface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: _reason == reason
                          ? AppColors.action500
                          : AppColors.inputBorder,
                    ),
                  ),
                  child: Text(
                    reason.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: _reason == reason
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (_reason == SocialReportReason.other) ...[
            TextField(
              controller: _detailsController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Ex.: Descreva o que aconteceu',
                filled: true,
                fillColor: AppColors.insetSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _reason == null
                ? null
                : () {
                    Navigator.of(context).pop(
                      SocialReportResult(
                        reason: _reason!,
                        details: _detailsController.text.trim().isEmpty
                            ? null
                            : _detailsController.text.trim(),
                      ),
                    );
                  },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.action500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            child: const Text('Enviar denúncia'),
          ),
        ],
      ),
    );
  }
}
