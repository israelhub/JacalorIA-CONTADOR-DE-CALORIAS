import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../home/pages/home_page.dart';
import '../../onboarding/pages/activity_level_page.dart';
import '../../onboarding/pages/objective_page.dart';
import '../../onboarding/pages/personal_data_page.dart';
import '../../onboarding/pages/welcome_page.dart';
import '../pages/email_confirmation_page.dart';
import '../pages/login_page.dart';
import '../pages/sign_up_page.dart';

class _PageShortcut {
  const _PageShortcut({required this.label, required this.builder});

  final String label;
  final Widget Function() builder;
}

class EnterPagesShortcutButton extends StatelessWidget {
  const EnterPagesShortcutButton({super.key});

  static const List<_PageShortcut> _pageShortcuts = [
    _PageShortcut(label: 'Criar conta', builder: SignUpPage.new),
    _PageShortcut(label: 'Login', builder: LoginPage.new),
    _PageShortcut(
      label: 'Confirmação de e-mail',
      builder: EmailConfirmationPage.new,
    ),
    _PageShortcut(label: 'Boas-vindas', builder: WelcomePage.new),
    _PageShortcut(label: 'Dados pessoais', builder: PersonalDataPage.new),
    _PageShortcut(label: 'Objetivo', builder: ObjectivePage.new),
    _PageShortcut(
      label: 'Nível de atividade física',
      builder: ActivityLevelPage.new,
    ),
    _PageShortcut(label: 'Home', builder: HomePage.new),
  ];

  void _openPagesQuickAccess(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.xl,
              AppSpacing.xxl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ir para página',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (_, index) {
                      final shortcut = _pageShortcuts[index];

                      return ListTile(
                        key: ValueKey('page-shortcut-${shortcut.label}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          shortcut.label,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: AppSpacing.lg,
                          color: AppColors.textSecondary,
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => shortcut.builder(),
                            ),
                          );
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: _pageShortcuts.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: TextButton.icon(
        key: const ValueKey('enter-pages-shortcut-button'),
        onPressed: () => _openPagesQuickAccess(context),
        icon: const Icon(Icons.map_outlined),
        label: const Text('Ver páginas já criadas'),
      ),
    );
  }
}
