import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../models/social_group_models.dart';
import 'social_search_result_item.dart';

class SocialSearchUserDialog extends StatefulWidget {
  const SocialSearchUserDialog({
    super.key,
    required this.searchUsers,
    required this.onAddUser,
  });

  final Future<List<SocialUserSearchResult>> Function(String query) searchUsers;
  final Future<void> Function(SocialUserSearchResult user) onAddUser;

  @override
  State<SocialSearchUserDialog> createState() => _SocialSearchUserDialogState();
}

class _SocialSearchUserDialogState extends State<SocialSearchUserDialog> {
  final TextEditingController _queryController = TextEditingController();
  final List<SocialUserSearchResult> _results = <SocialUserSearchResult>[];
  bool _searching = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(_results.clear);
      return;
    }

    setState(() => _searching = true);
    final found = await widget.searchUsers(query);
    if (!mounted) return;
    setState(() {
      _results
        ..clear()
        ..addAll(found);
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.performanceCardBorder, width: 2),
          boxShadow: AppShadows.performanceCard,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Buscar usuário',
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
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _queryController,
                decoration: InputDecoration(
                  hintText: 'Digite ID ou e-mail',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _runSearch(),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(label: 'Buscar usuário', onPressed: _runSearch),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _searching
                    ? const Center(child: CircularProgressIndicator(color: AppColors.action500))
                    : _results.isEmpty
                    ? Center(
                        child: Text(
                          'Sem resultados ainda.',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final user in _results) ...[
                              SocialSearchResultItem(
                                user: user,
                                onAdd: !user.canSendRequest
                                    ? null
                                    : () async {
                                        await widget.onAddUser(user);
                                        if (!mounted) return;
                                        setState(() {
                                          final index = _results.indexOf(user);
                                          if (index >= 0) {
                                            _results[index] = SocialUserSearchResult(
                                              id: user.id,
                                              name: user.name,
                                              email: user.email,
                                              avatarUrl: user.avatarUrl,
                                              avatarFrameId: user.avatarFrameId,
                                              isFriend: false,
                                              friendRequestStatus: 'outgoing',
                                            );
                                          }
                                        });
                                      },
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
