import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/app_select_input_field.dart';
import '../models/social_group_models.dart';
import 'social_group_card.dart';

class SocialPublicGroupsDialog extends StatefulWidget {
  const SocialPublicGroupsDialog({
    super.key,
    required this.fetchGroups,
  });

  final Future<List<SocialGroupSummary>> Function({
    required String query,
    int? durationDays,
    String? competitionType,
  }) fetchGroups;

  @override
  State<SocialPublicGroupsDialog> createState() => _SocialPublicGroupsDialogState();
}

class _SocialPublicGroupsDialogState extends State<SocialPublicGroupsDialog> {
  final TextEditingController _queryController = TextEditingController();
  int? _durationDays;
  String? _competitionType;
  bool _loading = true;
  String? _error;
  List<SocialGroupSummary> _groups = const [];

  static const List<int> _durations = <int>[7, 14, 21, 30, 0];
  static const List<MapEntry<String, String>> _types = <MapEntry<String, String>>[
    MapEntry('offensive', 'Sequência'),
    MapEntry('daily_goal', 'Meta diária'),
    MapEntry('xp', 'XP'),
    MapEntry('group_streak', 'Sequência dos amigos'),
  ];
  static const String _anyDuration = 'Qualquer';
  static const String _anyCompetition = 'Qualquer';

  String get _selectedDurationLabel {
    if (_durationDays == null) return _anyDuration;
    return _durationDays == 0 ? 'Infinito' : '${_durationDays!} dias';
  }

  List<String> get _durationOptions => <String>[
    _anyDuration,
    ..._durations.map((v) => v == 0 ? 'Infinito' : '$v dias'),
  ];

  String get _selectedCompetitionLabel {
    if (_competitionType == null) return _anyCompetition;
    final match = _types.where((entry) => entry.key == _competitionType);
    if (match.isEmpty) return _anyCompetition;
    return match.first.value;
  }

  List<String> get _competitionOptions => <String>[
    _anyCompetition,
    ..._types.map((entry) => entry.value),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final groups = await widget.fetchGroups(
        query: _queryController.text.trim(),
        durationDays: _durationDays,
        competitionType: _competitionType,
      );
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 680),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Grupos públicos',
                    style: AppTextStyles.missionsSectionTitle.copyWith(
                      color: AppColors.brand900Variant,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            AppInputField(
              label: '',
              hint: 'Nome do grupo',
              controller: _queryController,
              suffixIcon: IconButton(
                onPressed: _load,
                icon: const Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppSelectInputField(
                    label: 'Tempo',
                    labelStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    selectedValue: _selectedDurationLabel,
                    options: _durationOptions,
                    onSelected: (value) {
                      setState(() {
                        if (value == _anyDuration) {
                          _durationDays = null;
                          return;
                        }
                        _durationDays = value == 'Infinito'
                            ? 0
                            : int.tryParse(value.replaceAll(' dias', ''));
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppSelectInputField(
                    label: 'Competição',
                    labelStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    selectedValue: _selectedCompetitionLabel,
                    options: _competitionOptions,
                    onSelected: (value) {
                      setState(() {
                        if (value == _anyCompetition) {
                          _competitionType = null;
                          return;
                        }
                        final match = _types.where((entry) => entry.value == value);
                        _competitionType = match.isEmpty ? null : match.first.key;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Aplicar filtros',
              variant: AppButtonVariant.outline,
              onPressed: _load,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.action500))
                  : _error != null
                  ? Center(child: Text(_error!))
                  : _groups.isEmpty
                  ? const Center(child: Text('Nenhum grupo público encontrado.'))
                  : ListView.separated(
                      itemCount: _groups.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final group = _groups[index];
                        return SocialGroupCard(
                          group: group,
                          onTap: () => Navigator.of(context).pop(group.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
