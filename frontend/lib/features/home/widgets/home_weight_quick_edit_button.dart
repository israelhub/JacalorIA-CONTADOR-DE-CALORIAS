import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_confirm_modal.dart';
import '../../../shared/widgets/app_floating_circle_button.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../auth/service/auth_service.dart';

export 'home_shell_layout.dart';

/// Opens the weight editor from an external trigger (ex.: card da home).
class HomeWeightQuickEditController {
  VoidCallback? _open;

  void open() => _open?.call();

  void _attach(VoidCallback open) => _open = open;

  void _detach(VoidCallback open) {
    if (identical(_open, open)) {
      _open = null;
    }
  }
}

Future<void> showHomeWeightEditSheet(
  BuildContext context, {
  required Map<String, dynamic>? userProfile,
  AuthService? authService,
  ValueChanged<Map<String, dynamic>>? onWeightUpdated,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _HomeWeightEditSheet(
        userProfile: userProfile,
        authService: authService,
        onWeightUpdated: onWeightUpdated,
      );
    },
  );
}

class HomeWeightQuickEditButton extends StatefulWidget {
  const HomeWeightQuickEditButton({
    super.key,
    required this.userProfile,
    this.authService,
    this.onWeightUpdated,
    this.controller,
    this.showTrigger = true,
  });

  final Map<String, dynamic>? userProfile;
  final AuthService? authService;
  final ValueChanged<Map<String, dynamic>>? onWeightUpdated;
  final HomeWeightQuickEditController? controller;

  /// When false, only the host is mounted (trigger via [controller]).
  final bool showTrigger;

  @override
  State<HomeWeightQuickEditButton> createState() =>
      _HomeWeightQuickEditButtonState();
}

class _HomeWeightQuickEditButtonState extends State<HomeWeightQuickEditButton> {
  @override
  void initState() {
    super.initState();
    widget.controller?._attach(_openEditor);
  }

  @override
  void didUpdateWidget(covariant HomeWeightQuickEditButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(_openEditor);
      widget.controller?._attach(_openEditor);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(_openEditor);
    super.dispose();
  }

  void _openEditor() {
    unawaited(
      showHomeWeightEditSheet(
        context,
        userProfile: widget.userProfile,
        authService: widget.authService,
        onWeightUpdated: widget.onWeightUpdated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showTrigger) {
      return const SizedBox.shrink();
    }

    return AppFloatingCircleButton(
      key: const ValueKey('home-weight-quick-edit-button'),
      icon: Icons.monitor_weight_outlined,
      semanticLabel: 'Atualizar peso',
      onPressed: _openEditor,
    );
  }
}

class _HomeWeightEditSheet extends StatefulWidget {
  const _HomeWeightEditSheet({
    required this.userProfile,
    this.authService,
    this.onWeightUpdated,
  });

  final Map<String, dynamic>? userProfile;
  final AuthService? authService;
  final ValueChanged<Map<String, dynamic>>? onWeightUpdated;

  @override
  State<_HomeWeightEditSheet> createState() => _HomeWeightEditSheetState();
}

class _HomeWeightEditSheetState extends State<_HomeWeightEditSheet> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  var _isSaving = false;
  var _isHandlingClose = false;

  AuthService get _authService => widget.authService ?? AuthService();

  double get _currentWeight {
    final rawWeight = widget.userProfile?['weight'];
    if (rawWeight is num) {
      return rawWeight.toDouble();
    }
    if (rawWeight is String && rawWeight.trim().isNotEmpty) {
      return double.tryParse(rawWeight.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }

  String get _currentUnit {
    final unit =
        (widget.userProfile?['weightUnit'] as String?) ??
        (widget.userProfile?['weight_unit'] as String?);
    return unit?.trim().isNotEmpty == true ? unit!.trim() : 'kg';
  }

  String _formatWeight(double value) {
    if (value <= 0) {
      return '';
    }
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  double? get _parsedWeight {
    final parsed = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  @override
  void initState() {
    super.initState();
    final text = _formatWeight(_currentWeight);
    _controller = TextEditingController(
      text: text,
    )..selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool _isUnchanged(double weight, String unit) {
    final current = widget.userProfile;
    final currentWeight = current?['weight'];
    final currentUnit =
        (current?['weightUnit'] as String?) ??
        (current?['weight_unit'] as String?) ??
        'kg';
    final sameWeight = currentWeight is num
        ? currentWeight.toDouble() == weight
        : double.tryParse('$currentWeight'.replaceAll(',', '.')) == weight;
    return sameWeight && currentUnit == unit;
  }

  bool get _hasUnsavedChanges {
    final weight = _parsedWeight;
    if (weight == null) {
      final initial = _formatWeight(_currentWeight);
      return _controller.text.trim() != initial.trim();
    }
    return !_isUnchanged(weight, _currentUnit);
  }

  Future<void> _requestClose() async {
    if (_isHandlingClose || _isSaving) {
      return;
    }

    if (!_hasUnsavedChanges) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    _isHandlingClose = true;
    try {
      _focusNode.unfocus();

      final shouldSave = await AppConfirmModal.show(
        context,
        title: 'Deseja salvar as alterações?',
        message: 'Você alterou o peso. Escolha se deseja salvar antes de sair.',
        confirmLabel: 'Salvar',
        cancelLabel: 'Não salvar',
        barrierDismissible: false,
      );

      if (!mounted) {
        return;
      }

      if (shouldSave) {
        final weight = _parsedWeight;
        if (weight == null) {
          if (mounted) {
            Navigator.of(context).pop();
          }
          return;
        }
        await _persistWeight(weight, _currentUnit, closeOnSuccess: true);
        return;
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      _isHandlingClose = false;
    }
  }

  Future<void> _submit() async {
    final weight = _parsedWeight;
    if (weight == null) {
      return;
    }
    await _persistWeight(weight, _currentUnit, closeOnSuccess: true);
  }

  Future<void> _persistWeight(
    double weight,
    String unit, {
    bool closeOnSuccess = false,
  }) async {
    setState(() => _isSaving = true);
    try {
      final updated = await _authService.updateProfile(<String, dynamic>{
        'weight': weight,
        'weightUnit': unit,
        'logWeightEntry': true,
      });
      widget.onWeightUpdated?.call(<String, dynamic>{
        ...updated,
        'weight': weight,
        'weightUnit': unit,
      });
      if (!mounted) {
        return;
      }
      AppToast.success(context, message: 'Peso atualizado.');
      if (closeOnSuccess) {
        Navigator.of(context).pop();
        return;
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, message: 'Erro ao salvar peso: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: !_hasUnsavedChanges && !_isSaving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _isHandlingClose || _isSaving) {
          return;
        }
        unawaited(_requestClose());
      },
      child: Padding(
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
                    'Atualizar peso',
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
                          key: const ValueKey('home-weight-edit-field'),
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.done,
                          enableSuggestions: false,
                          autocorrect: false,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                            LengthLimitingTextInputFormatter(6),
                          ],
                          style: AppTextStyles.headingLarge.copyWith(
                            color: AppColors.brand900Variant,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Ex.: 70',
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
                        _currentUnit,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Salvar',
                    onPressed: _parsedWeight == null || _isSaving
                        ? null
                        : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
