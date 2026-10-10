import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';

Future<int?> showHomeAddWaterSheet(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return const _HomeAddWaterSheet();
    },
  );
}

class _HomeAddWaterSheet extends StatefulWidget {
  const _HomeAddWaterSheet();

  @override
  State<_HomeAddWaterSheet> createState() => _HomeAddWaterSheetState();
}

class _HomeAddWaterSheetState extends State<_HomeAddWaterSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  int? get _parsedAmount {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = _parsedAmount;
    if (amount == null) {
      return;
    }
    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
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
                  'Registrar água',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 96,
                        maxWidth: 180,
                      ),
                      child: TextField(
                        key: const ValueKey('home-water-edit-field'),
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        enableSuggestions: false,
                        autocorrect: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5),
                        ],
                        style: AppTextStyles.headingLarge.copyWith(
                          color: AppColors.brand900Variant,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Ex.: 250',
                          hintStyle: AppTextStyles.headingLarge.copyWith(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'ml',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Salvar',
                  onPressed: _parsedAmount == null ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
