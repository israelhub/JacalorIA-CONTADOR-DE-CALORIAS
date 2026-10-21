import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../food_analysis/helpers/image_optimizer.dart';
import '../../../../shared/services/supabase_storage_service.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_back_page_header.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_confirm_modal.dart';
import '../../../../shared/widgets/app_date_picker.dart';
import '../../../../shared/widgets/app_dropdown_menu.dart';
import '../../../../shared/widgets/app_form_card.dart';
import '../../../../shared/widgets/app_input.dart';
import '../../../../shared/widgets/app_page_route.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/measurement_input_field.dart';
import '../../auth/pages/enter_page.dart';
import '../../auth/service/auth_service.dart';
import '../../home/widgets/home_shell_layout.dart';
import '../../legal/helpers/age_gate.dart';
import '../../legal/pages/privacy_policy_page.dart';
import '../../legal/pages/terms_page.dart';
import '../helpers/profile_date_helpers.dart';
import '../widgets/profile_privacy_card.dart';
import '../widgets/profile_section_card.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key, required this.initialProfile});

  final Map<String, dynamic> initialProfile;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _objectiveController = TextEditingController();
  final _activityController = TextEditingController();

  String? _selectedSex;
  String? _selectedObjective;
  String? _selectedActivityLevel;
  String? _avatarUrl;
  String _selectedWeightUnit = 'kg';
  String _selectedHeightUnit = 'cm';
  bool _isSaving = false;
  bool _isHandlingExit = false;
  bool _isEditing = false;
  bool _isExportingData = false;
  bool _isDeletingAccount = false;
  bool _didSave = false;

  String _initialName = '';
  String _initialBirthDate = '';
  String _initialWeight = '';
  String _initialHeight = '';
  String? _initialSex;
  String? _initialObjective;
  String? _initialActivityLevel;
  String? _initialAvatarUrl;
  String _initialWeightUnit = 'kg';
  String _initialHeightUnit = 'cm';
  bool _hidePublicProfileMeals = false;
  bool _initialHidePublicProfileMeals = false;
  bool _hidePublicProfileWorkouts = false;
  bool _initialHidePublicProfileWorkouts = false;
  bool _analyticsOptOut = false;
  bool _initialAnalyticsOptOut = false;

  static const List<String> _sexOptions = [
    'Masculino',
    'Feminino',
  ];

  static const Map<String, String> _objectiveLabels = {
    'loseWeight': 'Emagrecer',
    'gainMass': 'Ganhar massa',
    'maintainWeight': 'Manter peso',
  };

  static const Map<String, String> _activityLabels = {
    'sedentary': 'Sedentário',
    'lightly': 'Levemente ativo',
    'moderate': 'Moderadamente ativo',
    'very': 'Muito ativo',
    'extreme': 'Extremamente ativo',
  };

  @override
  void initState() {
    super.initState();
    _hydrateProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _objectiveController.dispose();
    _activityController.dispose();
    super.dispose();
  }

  void _hydrateProfile() {
    final profile = widget.initialProfile;

    _nameController.text = (profile['name'] as String?) ?? '';
    _avatarUrl =
        (profile['avatarUrl'] as String?) ?? (profile['avatar_url'] as String?);

    final birthDateRaw =
        (profile['birthDate'] as String?) ?? (profile['birth_date'] as String?);
    if (birthDateRaw != null && birthDateRaw.isNotEmpty) {
      _birthDateController.text = formatProfileDisplayDate(birthDateRaw);
    }

    final weight = profile['weight'];
    final height = profile['height'];
    final weightUnit =
        (profile['weightUnit'] as String?) ??
        (profile['weight_unit'] as String?);
    final heightUnit =
        (profile['heightUnit'] as String?) ??
        (profile['height_unit'] as String?);

    if (weight is num) {
      _weightController.text = _formatNumber(weight);
    } else if (weight is String && weight.trim().isNotEmpty) {
      final parsedWeight = num.tryParse(weight.replaceAll(',', '.'));
      if (parsedWeight != null) {
        _weightController.text = _formatNumber(parsedWeight);
      }
    }

    if (height is num) {
      _heightController.text = _formatNumber(height);
    } else if (height is String && height.trim().isNotEmpty) {
      final parsedHeight = num.tryParse(height.replaceAll(',', '.'));
      if (parsedHeight != null) {
        _heightController.text = _formatNumber(parsedHeight);
      }
    }

    _selectedWeightUnit = weightUnit?.trim().isNotEmpty == true
        ? weightUnit!.trim()
        : 'kg';
    _selectedHeightUnit = heightUnit?.trim().isNotEmpty == true
        ? heightUnit!.trim()
        : 'cm';

    _selectedSex = profile['sex'] as String?;
    _selectedObjective = _normalizeObjective(profile['objective'] as String?);
    _selectedActivityLevel =
        (profile['activityLevel'] as String?) ??
        (profile['activity_level'] as String?);

    _objectiveController.text = _objectiveLabels[_selectedObjective] ?? '';
    _activityController.text = _activityLabels[_selectedActivityLevel] ?? '';
    _hidePublicProfileMeals = _boolFromProfile(profile, const [
      'hidePublicProfileMeals',
      'hide_public_profile_meals',
    ]);
    _hidePublicProfileWorkouts = _boolFromProfile(profile, const [
      'hidePublicProfileWorkouts',
      'hide_public_profile_workouts',
    ]);
    _analyticsOptOut = _boolFromProfile(profile, const [
      'analyticsOptOut',
      'analytics_opt_out',
    ]);
    AnalyticsService.instance.syncOptOutFromProfile(profile);
    _captureInitialSnapshot();
  }

  void _captureInitialSnapshot() {
    _initialName = _nameController.text;
    _initialBirthDate = _birthDateController.text;
    _initialWeight = _weightController.text;
    _initialHeight = _heightController.text;
    _initialSex = _selectedSex;
    _initialObjective = _selectedObjective;
    _initialActivityLevel = _selectedActivityLevel;
    _initialAvatarUrl = _avatarUrl;
    _initialWeightUnit = _selectedWeightUnit;
    _initialHeightUnit = _selectedHeightUnit;
    _initialHidePublicProfileMeals = _hidePublicProfileMeals;
    _initialHidePublicProfileWorkouts = _hidePublicProfileWorkouts;
    _initialAnalyticsOptOut = _analyticsOptOut;
  }

  void _restoreFromSnapshot() {
    _nameController.text = _initialName;
    _birthDateController.text = _initialBirthDate;
    _weightController.text = _initialWeight;
    _heightController.text = _initialHeight;
    _selectedSex = _initialSex;
    _selectedObjective = _initialObjective;
    _selectedActivityLevel = _initialActivityLevel;
    _avatarUrl = _initialAvatarUrl;
    _selectedWeightUnit = _initialWeightUnit;
    _selectedHeightUnit = _initialHeightUnit;
    _hidePublicProfileMeals = _initialHidePublicProfileMeals;
    _hidePublicProfileWorkouts = _initialHidePublicProfileWorkouts;
    _analyticsOptOut = _initialAnalyticsOptOut;
    _objectiveController.text = _objectiveLabels[_selectedObjective] ?? '';
    _activityController.text = _activityLabels[_selectedActivityLevel] ?? '';
  }

  bool get _hasUnsavedChanges {
    return _nameController.text != _initialName ||
        _birthDateController.text != _initialBirthDate ||
        _weightController.text != _initialWeight ||
        _heightController.text != _initialHeight ||
        _selectedSex != _initialSex ||
        _selectedObjective != _initialObjective ||
        _selectedActivityLevel != _initialActivityLevel ||
        _avatarUrl != _initialAvatarUrl ||
        _selectedWeightUnit != _initialWeightUnit ||
        _selectedHeightUnit != _initialHeightUnit ||
        _hidePublicProfileMeals != _initialHidePublicProfileMeals ||
        _hidePublicProfileWorkouts != _initialHidePublicProfileWorkouts ||
        _analyticsOptOut != _initialAnalyticsOptOut;
  }

  bool get _busy =>
      _isSaving || _isExportingData || _isDeletingAccount || _isHandlingExit;

  String _displayOrDash(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '—' : trimmed;
  }

  String get _weightDisplay {
    final value = _weightController.text.trim();
    if (value.isEmpty) {
      return '—';
    }
    return '$value $_selectedWeightUnit';
  }

  String get _heightDisplay {
    final value = _heightController.text.trim();
    if (value.isEmpty) {
      return '—';
    }
    return '$value $_selectedHeightUnit';
  }

  Future<void> _handleExitAttempt() async {
    if (_busy) {
      return;
    }

    if (_isEditing) {
      await _cancelEditing();
      return;
    }

    Navigator.of(context).pop(_didSave);
  }

  Future<void> _cancelEditing() async {
    if (!_hasUnsavedChanges) {
      setState(() => _isEditing = false);
      return;
    }

    _isHandlingExit = true;
    try {
      final shouldSave = await AppConfirmModal.show(
        context,
        title: 'Deseja salvar as alterações?',
        message:
            'Você editou dados do perfil. Escolha se deseja salvar antes de sair.',
        confirmLabel: 'Salvar',
        cancelLabel: 'Não salvar',
        barrierDismissible: false,
      );

      if (!mounted) {
        return;
      }

      if (shouldSave) {
        await _saveProfile();
      } else {
        setState(() {
          _restoreFromSnapshot();
          _isEditing = false;
        });
      }
    } finally {
      _isHandlingExit = false;
    }
  }

  String _formatNumber(num value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String? _normalizeObjective(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    const map = <String, String>{
      'loseweight': 'loseWeight',
      'lose_weight': 'loseWeight',
      'gainmass': 'gainMass',
      'gain_mass': 'gainMass',
      'gainmuscle': 'gainMass',
      'gain_muscle': 'gainMass',
      'maintainweight': 'maintainWeight',
      'maintain_weight': 'maintainWeight',
      'maintenance': 'maintainWeight',
    };

    final normalizedKey = raw.toLowerCase().replaceAll(RegExp(r'[^a-z_]'), '');
    return map[normalizedKey] ?? raw;
  }

  bool _boolFromProfile(Map<String, dynamic> profile, List<String> keys) {
    for (final key in keys) {
      final value = profile[key];
      if (value is bool) {
        return value;
      }
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') {
          return true;
        }
        if (normalized == 'false' || normalized == '0') {
          return false;
        }
      }
    }
    return false;
  }

  Future<void> _pickBirthDate() async {
    final maxBirth = AgeGate.maxBirthDate();
    final initialDate = maxBirth;

    final selectedDate = await showAppDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: AgeGate.minBirthDate(),
      lastDate: maxBirth,
    );

    if (selectedDate == null) {
      return;
    }

    final day = selectedDate.day.toString().padLeft(2, '0');
    final month = selectedDate.month.toString().padLeft(2, '0');
    final year = selectedDate.year.toString();

    setState(() {
      _birthDateController.text = '$day/$month/$year';
    });
  }

  Future<void> _pickAvatar() async {
    if (!_isEditing || _busy) {
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 640,
      maxHeight: 640,
      imageQuality: 85,
    );
    if (picked == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final avatarBytes = await picked.readAsBytes();
      final optimized = await optimizeForAvatar(avatarBytes);
      final uploadedUrl = await SupabaseStorageService.uploadAvatarBytes(
        optimized.bytes,
        extension: '.jpg',
      );
      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        if (mounted) {
          AppToast.error(context, message: 'Falha ao enviar foto de perfil.');
        }
        return;
      }

      setState(() {
        _avatarUrl = uploadedUrl;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) {
      return;
    }

    final birthDisplay = _birthDateController.text.trim();
    if (birthDisplay.isNotEmpty && !AgeGate.isAtLeastMinimumAge(birthDisplay)) {
      AppToast.error(context, message: AgeGate.minimumAgeMessage());
      return;
    }

    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final height = double.tryParse(_heightController.text.replaceAll(',', '.'));

    final data = <String, dynamic>{
      if (_nameController.text.trim().isNotEmpty)
        'name': _nameController.text.trim(),
      if (toProfileApiDate(_birthDateController.text) != null)
        'birthDate': toProfileApiDate(_birthDateController.text),
      if (weight != null && weight > 0) 'weight': weight,
      if (height != null && height > 0) 'height': height,
      'weightUnit': _selectedWeightUnit,
      'heightUnit': _selectedHeightUnit,
      if (_selectedActivityLevel != null)
        'activityLevel': _selectedActivityLevel,
      if (_selectedSex != null) 'sex': _selectedSex,
      if (_selectedObjective != null) 'objective': _selectedObjective,
      if (_avatarUrl != null && _avatarUrl!.isNotEmpty) 'avatarUrl': _avatarUrl,
      'hidePublicProfileMeals': _hidePublicProfileMeals,
      'hidePublicProfileWorkouts': _hidePublicProfileWorkouts,
      'analyticsOptOut': _analyticsOptOut,
    };

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = await _authService.updateProfile(data);
      await AnalyticsService.instance.setOptOut(_analyticsOptOut);
      AnalyticsService.instance.syncOptOutFromProfile(updated);
      if (!mounted) {
        return;
      }
      _captureInitialSnapshot();
      _didSave = true;
      setState(() => _isEditing = false);
      AppToast.success(context, message: 'Dados salvos.');
    } catch (e) {
      if (mounted) {
        AppToast.error(context, message: 'Erro ao salvar perfil: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _exportMyData() async {
    if (_busy) {
      return;
    }

    setState(() => _isExportingData = true);
    try {
      final payload = await _authService.exportUserData();
      final jsonText = const JsonEncoder.withIndent('  ').convert(payload);
      final bytes = Uint8List.fromList(utf8.encode(jsonText));
      final file = XFile.fromData(
        bytes,
        mimeType: 'application/json',
        name: 'jacaloria-meus-dados.json',
      );
      await Share.shareXFiles(
        [file],
        subject: 'Meus dados JacalorIA',
        text: 'Exportação dos seus dados pessoais (LGPD).',
      );
      if (!mounted) {
        return;
      }
      AppToast.success(
        context,
        message: 'Arquivo pronto para salvar ou enviar.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.error(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingData = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    if (_busy) {
      return;
    }

    final confirmed = await AppConfirmModal.show(
      context,
      title: 'Excluir conta?',
      message:
          'Isso apaga permanentemente sua conta, refeições, treinos e demais '
          'dados pessoais. Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir conta',
      isDanger: true,
    );
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isDeletingAccount = true);
    try {
      await _authService.deleteAccount();
      if (!mounted) {
        return;
      }
      AppToast.success(context, message: 'Conta excluída com sucesso.');
      context.pushAndRemoveUntilSlidePage(const EnterPage(), (route) => false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.error(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeletingAccount = false);
      }
    }
  }

  Widget _buildAvatar({required bool editable}) {
    final avatarUrl = _avatarUrl;
    final initial = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()[0].toUpperCase()
        : 'P';

    return Center(
      child: GestureDetector(
        onTap: editable && !_busy ? _pickAvatar : null,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.insetSurface,
              backgroundImage: avatarUrl?.startsWith('http') == true
                  ? CachedNetworkImageProvider(avatarUrl!)
                  : null,
              child: avatarUrl?.startsWith('http') == true
                  ? null
                  : Text(
                      initial,
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.brand900Variant,
                      ),
                    ),
            ),
            if (editable)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.action500,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: AppColors.surface,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileDataRow(
            icon: PhosphorIcons.user(PhosphorIconsStyle.regular),
            label: 'Nome',
            value: _displayOrDash(_nameController.text),
          ),
          const SizedBox(height: AppSpacing.xl),
          _ProfileDataRow(
            icon: PhosphorIcons.calendarBlank(PhosphorIconsStyle.regular),
            label: 'Data de nascimento',
            value: _displayOrDash(_birthDateController.text),
          ),
          const SizedBox(height: AppSpacing.xl),
          _ProfileDataRow(
            icon: PhosphorIcons.scales(PhosphorIconsStyle.regular),
            label: 'Peso',
            value: _weightDisplay,
          ),
          const SizedBox(height: AppSpacing.xl),
          _ProfileDataRow(
            icon: PhosphorIcons.ruler(PhosphorIconsStyle.regular),
            label: 'Altura',
            value: _heightDisplay,
          ),
          const SizedBox(height: AppSpacing.xl),
          _ProfileDataRow(
            icon: PhosphorIcons.personSimpleRun(PhosphorIconsStyle.regular),
            label: 'Nível de atividade',
            value: _displayOrDash(_activityController.text),
          ),
          const SizedBox(height: AppSpacing.xl),
          _ProfileDataRow(
            icon: PhosphorIcons.genderIntersex(PhosphorIconsStyle.regular),
            label: 'Sexo',
            value: _displayOrDash(_selectedSex ?? ''),
          ),
          const SizedBox(height: AppSpacing.xl),
          _ProfileDataRow(
            icon: PhosphorIcons.target(PhosphorIconsStyle.regular),
            label: 'Objetivo',
            value: _displayOrDash(_objectiveController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildEditFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInputField(
          label: 'Nome',
          hint: '',
          controller: _nameController,
          enabled: !_busy,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppInputField(
          label: 'Data de nascimento',
          hint: '',
          controller: _birthDateController,
          readOnly: true,
          enabled: !_busy,
          onTap: _busy ? null : _pickBirthDate,
          suffixIcon: IconButton(
            onPressed: _busy ? null : _pickBirthDate,
            color: AppColors.textSecondary,
            icon: const Icon(Icons.calendar_today_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        MeasurementInputField(
          label: 'Peso',
          hint: '',
          controller: _weightController,
          unitSelectorKey: const ValueKey('profile-edit-weight-unit-selector'),
          selectedUnit: _selectedWeightUnit,
          unitOptions: const ['kg', 'lb', 'g'],
          onUnitSelected: _busy
              ? (_) {}
              : (unit) {
                  setState(() {
                    _selectedWeightUnit = unit;
                  });
                },
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: AppSpacing.lg),
        MeasurementInputField(
          label: 'Altura',
          hint: '',
          controller: _heightController,
          unitSelectorKey: const ValueKey('profile-edit-height-unit-selector'),
          selectedUnit: _selectedHeightUnit,
          unitOptions: const ['cm', 'm', 'ft', 'in'],
          onUnitSelected: _busy
              ? (_) {}
              : (unit) {
                  setState(() {
                    _selectedHeightUnit = unit;
                  });
                },
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppDropdownMenu(
          fieldKey: const ValueKey('profile-edit-activity-field'),
          label: 'Nível de atividade',
          hint: '',
          selectedValue: _activityController.text,
          options: _activityLabels.values.toList(),
          onSelected: _busy
              ? (_) {}
              : (value) {
                  final entry = _activityLabels.entries.firstWhere(
                    (entry) => entry.value == value,
                    orElse: () => const MapEntry('sedentary', 'Sedentário'),
                  );
                  setState(() {
                    _selectedActivityLevel = entry.key;
                    _activityController.text = entry.value;
                  });
                },
        ),
        const SizedBox(height: AppSpacing.lg),
        AppDropdownMenu(
          fieldKey: const ValueKey('profile-edit-sex-field'),
          label: 'Sexo',
          hint: '',
          selectedValue: _selectedSex ?? '',
          options: _sexOptions,
          onSelected: _busy
              ? (_) {}
              : (value) {
                  setState(() {
                    _selectedSex = value;
                  });
                },
        ),
        const SizedBox(height: AppSpacing.lg),
        AppDropdownMenu(
          fieldKey: const ValueKey('profile-edit-objective-field'),
          label: 'Objetivo',
          hint: '',
          selectedValue: _objectiveController.text,
          options: _objectiveLabels.values.toList(),
          onSelected: _busy
              ? (_) {}
              : (value) {
                  final entry = _objectiveLabels.entries.firstWhere(
                    (entry) => entry.value == value,
                    orElse: () =>
                        const MapEntry('maintainWeight', 'Manter peso'),
                  );
                  setState(() {
                    _selectedObjective = entry.key;
                    _objectiveController.text = entry.value;
                  });
                },
        ),
      ],
    );
  }

  Widget _buildLegalActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppSpacing.huge + AppSpacing.xs,
          child: AppButton(
            label: 'Política de Privacidade',
            onPressed: _busy
                ? null
                : () {
                    context.pushSlidePage(const PrivacyPolicyPage());
                  },
            variant: AppButtonVariant.outline,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: AppSpacing.huge + AppSpacing.xs,
          child: AppButton(
            label: 'Termos e Condições',
            onPressed: _busy
                ? null
                : () {
                    context.pushSlidePage(const TermsPage());
                  },
            variant: AppButtonVariant.outline,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: AppSpacing.huge + AppSpacing.xs,
          child: AppButton(
            label: _isExportingData ? 'Exportando...' : 'Baixar meus dados',
            onPressed: _busy ? null : _exportMyData,
            variant: AppButtonVariant.outline,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: AppSpacing.huge + AppSpacing.xs,
          child: AppButton(
            label: _isDeletingAccount ? 'Excluindo...' : 'Excluir conta',
            onPressed: _busy ? null : _deleteAccount,
            variant: AppButtonVariant.danger,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _handleExitAttempt();
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        extendBodyBehindAppBar: true,
        appBar: const AppBackPageHeader(
          title: 'Editar dados pessoais',
          backgroundColor: Colors.transparent,
        ),
        body: AppBackPageContent(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppBackPageHeader.scrollTopInset(context, extra: AppSpacing.lg),
              AppSpacing.pageHorizontal,
              homeShellScrollBottomInset(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppFormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAvatar(editable: _isEditing),
                      const SizedBox(height: AppSpacing.xl),
                      if (_isEditing)
                        _buildEditFields()
                      else
                        _buildViewFields(),
                      const SizedBox(height: AppSpacing.xxxl),
                      if (_isEditing) ...[
                        SizedBox(
                          height: AppSpacing.huge + AppSpacing.xs,
                          child: Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: 'Cancelar',
                                  onPressed: _busy ? null : _cancelEditing,
                                  variant: AppButtonVariant.outline,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: AppButton(
                                  label: _isSaving
                                      ? 'Salvando...'
                                      : 'Salvar',
                                  onPressed: _busy ? null : _saveProfile,
                                  variant: AppButtonVariant.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          height: AppSpacing.huge + AppSpacing.xs,
                          child: AppButton(
                            label: 'Editar',
                            onPressed: _busy
                                ? null
                                : () {
                                    setState(() => _isEditing = true);
                                  },
                            variant: AppButtonVariant.primary,
                            trailingIcon: Icons.edit_rounded,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.cardGap),
                ProfileSectionCard(
                  title: 'Privacidade',
                  child: ProfilePrivacyCard(
                    showTitle: false,
                    mealsVisible: !_hidePublicProfileMeals,
                    workoutsVisible: !_hidePublicProfileWorkouts,
                    analyticsEnabled: !_analyticsOptOut,
                    busy: !_isEditing || _busy,
                    onMealsVisibleChanged: (visible) {
                      setState(() {
                        _hidePublicProfileMeals = !visible;
                      });
                    },
                    onWorkoutsVisibleChanged: (visible) {
                      setState(() {
                        _hidePublicProfileWorkouts = !visible;
                      });
                    },
                    onAnalyticsEnabledChanged: (enabled) {
                      setState(() {
                        _analyticsOptOut = !enabled;
                      });
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.cardGap),
                ProfileSectionCard(
                  title: 'Privacidade e dados',
                  child: _buildLegalActions(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileDataRow extends StatelessWidget {
  const _ProfileDataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: AppColors.textPrimary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
