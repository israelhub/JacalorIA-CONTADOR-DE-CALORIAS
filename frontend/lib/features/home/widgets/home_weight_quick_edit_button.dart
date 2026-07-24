import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_confirm_modal.dart';
import '../../../shared/widgets/app_floating_circle_button.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../auth/service/auth_service.dart';

/// Gap between shell FABs and the top of the bottom navigation.
const homeShellFabNavGap = AppSpacing.lg;

/// Fallback nav body height (surface + camera overlap) when [MediaQuery.padding]
/// has not yet absorbed the shell bar.
const homeShellBottomNavBodyHeight = 56.0 + AppSpacing.xs;

/// Bottom inset for FABs on tab pages under the home shell (`extendBody: true`).
///
/// With `extendBody`, Flutter moves the bottom-nav height into
/// [MediaQuery.padding] and zeroes [MediaQuery.viewPadding]. Nested Scaffold
/// FABs do not honor that padding in `contentBottom`, so we apply it here.
double homeShellFabBottomInset(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final shellOverlap = mediaQuery.padding.bottom > mediaQuery.viewPadding.bottom
      ? mediaQuery.padding.bottom
      : homeShellBottomNavBodyHeight + mediaQuery.viewPadding.bottom;
  return shellOverlap + homeShellFabNavGap;
}

/// Opens [HomeWeightQuickEditButton] from an external trigger (e.g. expandable FAB).
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

  /// When false, only the overlay host is mounted (trigger via [controller]).
  final bool showTrigger;

  @override
  State<HomeWeightQuickEditButton> createState() =>
      _HomeWeightQuickEditButtonState();
}

class _HomeWeightQuickEditButtonState extends State<HomeWeightQuickEditButton> {
  final OverlayPortalController _portalController = OverlayPortalController();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// Pre-mounted host keeps [_focusNode] attached so the FAB tap can open the
  /// IME inside the same user gesture. While the sheet is open, the visible
  /// field owns the node instead.
  final TextEditingController _hostController = TextEditingController();
  final FocusNode _hostFocusNode = FocusNode();

  var _isSaving = false;
  var _isOpen = false;
  var _isHandlingClose = false;

  AuthService get _authService => widget.authService ?? AuthService();

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
  void dispose() {
    widget.controller?._detach(_openEditor);
    _focusNode.dispose();
    _controller.dispose();
    _hostFocusNode.dispose();
    _hostController.dispose();
    super.dispose();
  }

  void _showKeyboard(FocusNode node) {
    node.requestFocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  void _primeKeyboard() {
    if (_isSaving) {
      return;
    }
    _showKeyboard(_hostFocusNode);
  }

  void _openEditor() {
    if (_isSaving || _isOpen) {
      return;
    }

    final text = _formatWeight(_currentWeight);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection(baseOffset: 0, extentOffset: text.length),
    );

    // Keep IME open from the pointer-down prime (same gesture).
    _showKeyboard(_hostFocusNode);

    setState(() => _isOpen = true);
    _portalController.show();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isOpen) {
        return;
      }
      _showKeyboard(_focusNode);
      Future<void>.delayed(const Duration(milliseconds: 30), () {
        if (mounted && _isOpen) {
          _showKeyboard(_focusNode);
        }
      });
    });
  }

  void _closeEditor() {
    if (!_isOpen) {
      return;
    }
    _focusNode.unfocus();
    _hostFocusNode.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    _portalController.hide();
    setState(() => _isOpen = false);
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
    if (!_isOpen || _isHandlingClose || _isSaving) {
      return;
    }

    if (!_hasUnsavedChanges) {
      _closeEditor();
      return;
    }

    _isHandlingClose = true;
    try {
      _focusNode.unfocus();
      _hostFocusNode.unfocus();
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');

      final shouldSave = await AppConfirmModal.show(
        context,
        title: 'Deseja salvar as alterações?',
        message:
            'Você alterou o peso. Escolha se deseja salvar antes de sair.',
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
          _closeEditor();
          return;
        }
        final unit = _currentUnit;
        _closeEditor();
        await _persistWeight(weight, unit);
        return;
      }

      _closeEditor();
    } finally {
      _isHandlingClose = false;
    }
  }

  Future<void> _submit() async {
    final weight = _parsedWeight;
    if (weight == null) {
      return;
    }
    final unit = _currentUnit;
    _closeEditor();
    await _persistWeight(weight, unit);
  }

  Future<void> _persistWeight(double weight, String unit) async {
    if (_isUnchanged(weight, unit)) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _authService.updateProfile(<String, dynamic>{
        'weight': weight,
        'weightUnit': unit,
      });
      widget.onWeightUpdated?.call(<String, dynamic>{
        'weight': weight,
        'weightUnit': unit,
      });
      if (mounted) {
        AppToast.success(context, message: 'Peso atualizado.');
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

  Widget _buildSheet(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _requestClose,
              child: const ColoredBox(color: Color(0x8A000000)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
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
                                keyboardType:
                                    const TextInputType.numberWithOptions(
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
                                  hintText: '0',
                                  hintStyle:
                                      AppTextStyles.headingLarge.copyWith(
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                ),
                                onChanged: (_) => setState(() {}),
                                onTap: () => _showKeyboard(_focusNode),
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
                          onPressed: _parsedWeight == null ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portalController,
      overlayChildBuilder: _buildSheet,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Non-zero layout (not Offstage): some platforms skip IME for
          // offstage/zero-size editors even when FocusNode.requestFocus succeeds.
          SizedBox(
            width: 1,
            height: 1,
            child: TextField(
              key: const ValueKey('home-weight-edit-field-host'),
              controller: _hostController,
              focusNode: _hostFocusNode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ),
          if (widget.showTrigger)
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _primeKeyboard(),
              child: AppFloatingCircleButton(
                key: const ValueKey('home-weight-quick-edit-button'),
                icon: Icons.monitor_weight_outlined,
                semanticLabel: 'Atualizar peso',
                onPressed: _openEditor,
              ),
            ),
        ],
      ),
    );
  }
}
