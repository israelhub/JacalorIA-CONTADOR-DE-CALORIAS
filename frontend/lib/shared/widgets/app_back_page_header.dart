import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_ambient_page_glow.dart';

class AppBackPageHeaderBar extends StatelessWidget {
  const AppBackPageHeaderBar({
    super.key,
    required this.title,
    this.actions = const <Widget>[],
    this.trailing,
    this.onBack,
    this.showBack = true,
    this.backButtonKey,
  });

  static const double chipHeight = 44;
  static const double chipGap = AppSpacing.sm;

  final String title;
  final List<Widget> actions;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool showBack;
  final Key? backButtonKey;

  @override
  Widget build(BuildContext context) {
    final hasActions = actions.isNotEmpty;
    final hasTrailing = trailing != null;

    return Row(
      children: [
        if (showBack) ...[
          _HeaderChip(
            child: SizedBox(
              width: chipHeight,
              height: chipHeight,
              child: IconButton(
                key: backButtonKey,
                tooltip: 'Voltar',
                padding: EdgeInsets.zero,
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.brand900Variant,
                  size: 22,
                ),
              ),
            ),
          ),
          if (title.trim().isNotEmpty) const SizedBox(width: chipGap),
        ],
        if (title.trim().isNotEmpty)
          Expanded(
            child: _HeaderChip(
              child: SizedBox(
                height: chipHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.homeSectionTitle.copyWith(
                        color: AppColors.brand900Variant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          const Spacer(),
        if (hasTrailing) ...[
          const SizedBox(width: chipGap),
          trailing!,
        ] else if (hasActions) ...[
          const SizedBox(width: chipGap),
          if (actions.length == 1)
            _HeaderChip(
              child: SizedBox(
                width: chipHeight,
                height: chipHeight,
                child: actions.first,
              ),
            )
          else
            _HeaderChip(
              child: SizedBox(
                height: chipHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [...actions],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class AppBackPageHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppBackPageHeader({
    super.key,
    required this.title,
    this.actions = const <Widget>[],
    this.trailing,
    this.backgroundColor = Colors.transparent,
    this.onBack,
    this.showBack = true,
    this.backButtonKey,
  });

  static const double barHeight = 64;

  final String title;
  final List<Widget> actions;
  final Widget? trailing;
  final Color backgroundColor;
  final VoidCallback? onBack;
  final bool showBack;
  final Key? backButtonKey;

  static double contentTopInset(BuildContext context) {
    final media = MediaQuery.of(context);
    // No body com extendBodyBehindAppBar o Scaffold zera viewPadding.top e
    // define padding.top como a altura real do AppBar; usar viewPadding aqui
    // subestima o inset no Android e o conteudo fica sob os chips.
    if (media.padding.top >= barHeight) {
      return media.padding.top;
    }
    final statusTop = media.padding.top > 0
        ? media.padding.top
        : media.viewPadding.top;
    return statusTop + barHeight;
  }

  static double scrollTopInset(BuildContext context, {double extra = 0}) {
    return contentTopInset(context) + extra;
  }

  @override
  Size get preferredSize => const Size.fromHeight(barHeight);

  @override
  Widget build(BuildContext context) {
    final isTransparent = backgroundColor.a == 0;
    final bar = SafeArea(
      bottom: false,
      child: SizedBox(
        height: barHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal,
          ),
          child: AppBackPageHeaderBar(
            title: title,
            actions: actions,
            trailing: trailing,
            onBack: onBack,
            showBack: showBack,
            backButtonKey: backButtonKey,
          ),
        ),
      ),
    );

    if (isTransparent) {
      return bar;
    }

    return ColoredBox(color: backgroundColor, child: bar);
  }
}

class AppBackPageContent extends StatelessWidget {
  const AppBackPageContent({
    super.key,
    required this.child,
    this.bottom = false,
  });

  final Widget child;
  final bool bottom;

  @override
  Widget build(BuildContext context) {
    return AppAmbientPageBody(
      child: SafeArea(top: false, bottom: bottom, child: child),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
