import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../helpers/social_group_helpers.dart';
import '../models/social_group_models.dart';
import '../services/social_service.dart';

class SocialCreateGroupSheet extends StatefulWidget {
  const SocialCreateGroupSheet({
    super.key,
    SocialService? service,
    this.existingGroup,
  }) : _service = service ?? const SocialService();

  final SocialService _service;
  final SocialGroupSummary? existingGroup;

  @override
  State<SocialCreateGroupSheet> createState() => _SocialCreateGroupSheetState();
}

class _SocialCreateGroupSheetState extends State<SocialCreateGroupSheet> {
  static const _icons = <_SocialIconOption>[
    _SocialIconOption('salad', Icons.eco_rounded),
    _SocialIconOption('muscle', Icons.fitness_center_rounded),
    _SocialIconOption('fire', Icons.local_fire_department_rounded),
    _SocialIconOption('trophy', Icons.emoji_events_rounded),
    _SocialIconOption('rocket', Icons.rocket_launch_rounded),
    _SocialIconOption('apple', Icons.restaurant_rounded),
    _SocialIconOption('avocado', Icons.favorite_rounded),
  ];

  static const _competitionTypes = <_CompetitionTypeOption>[
    _CompetitionTypeOption('offensive', 'Ofensiva'),
    _CompetitionTypeOption('daily_goal', 'Meta diária'),
    _CompetitionTypeOption('calories', 'Calorias'),
    _CompetitionTypeOption('xp', 'XP'),
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedIconKey = 'salad';
  String _selectedCompetitionType = 'offensive';
  int _selectedDurationDays = 7;
  bool _isSaving = false;

  bool get _isEditing => widget.existingGroup != null;

  static const List<int> _durationOptions = <int>[7, 14, 21, 30];

  @override
  void initState() {
    super.initState();

    final group = widget.existingGroup;
    if (group != null) {
      _nameController.text = group.name;
      _descriptionController.text = group.description;
      _selectedIconKey = group.iconKey;
      _selectedCompetitionType = group.competitionType;
      _selectedDurationDays = group.durationDays;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _descriptionController.text.trim().isNotEmpty &&
      !_isSaving;

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final result = _isEditing
          ? await widget._service.updateGroup(
              groupId: widget.existingGroup!.id,
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              competitionType: _selectedCompetitionType,
              iconKey: _selectedIconKey,
              durationDays: _selectedDurationDays,
            )
          : await widget._service.createGroup(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              competitionType: _selectedCompetitionType,
              iconKey: _selectedIconKey,
              durationDays: _selectedDurationDays,
            );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<SocialGroupDetail>(result);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.xs,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing ? 'Editar grupo' : 'Novo grupo',
                        style: AppTextStyles.missionsSectionTitle.copyWith(
                          color: AppColors.brand900Variant,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Ícone',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final option in _icons)
                      _IconPickerOption(
                        icon: option.icon,
                        selected: option.key == _selectedIconKey,
                        onTap: () {
                          setState(() {
                            _selectedIconKey = option.key;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppInputField(
                  label: 'Nome do grupo',
                  hint: 'Ex: Família Saudável',
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                AppInputField(
                  label: 'Descrição',
                  hint: 'Sobre o grupo',
                  controller: _descriptionController,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Tempo do desafio',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var index = 0; index < _durationOptions.length; index++) ...[
                        if (index > 0) const SizedBox(width: AppSpacing.sm),
                        _DurationChip(
                          value: _durationOptions[index],
                          label: socialDurationLabel(_durationOptions[index]),
                          selected: _durationOptions[index] == _selectedDurationDays,
                          onTap: () {
                            setState(() {
                              _selectedDurationDays = _durationOptions[index];
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Tipo de competição',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var index = 0; index < _competitionTypes.length; index++) ...[
                        if (index > 0) const SizedBox(width: AppSpacing.sm),
                        _CompetitionTypeChip(
                          label: _competitionTypes[index].label,
                          selected:
                              _competitionTypes[index].key == _selectedCompetitionType,
                          onTap: () {
                            setState(() {
                              _selectedCompetitionType = _competitionTypes[index].key;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 56,
                  child: Opacity(
                    opacity: _canSubmit ? 1 : 0.5,
                    child: AppButton(
                      label: _isSaving
                          ? (_isEditing ? 'Salvando...' : 'Criando...')
                          : (_isEditing ? 'Salvar alterações' : 'Criar grupo'),
                      onPressed: _canSubmit ? _submit : null,
                      variant: AppButtonVariant.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialIconOption {
  const _SocialIconOption(this.key, this.icon);

  final String key;
  final IconData icon;
}

class _CompetitionTypeOption {
  const _CompetitionTypeOption(this.key, this.label);

  final String key;
  final String label;
}

class _IconPickerOption extends StatelessWidget {
  const _IconPickerOption({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? AppColors.missionsXpPill : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.action500 : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: selected ? AppColors.action500 : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _CompetitionTypeChip extends StatelessWidget {
  const _CompetitionTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.action500 : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.captionStrong.copyWith(
            color: selected ? AppColors.surface : AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.value,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: ValueKey('social-duration-$value'),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.action500 : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.captionStrong.copyWith(
            color: selected ? AppColors.surface : AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
