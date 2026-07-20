import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../models/social_group_models.dart';
import '../widgets/social_search_result_item.dart';

class SocialSearchUserPage extends StatefulWidget {
  const SocialSearchUserPage({
    super.key,
    required this.searchUsers,
    required this.onAddUser,
  });

  final Future<List<SocialUserSearchResult>> Function(String query) searchUsers;
  final Future<void> Function(SocialUserSearchResult user) onAddUser;

  @override
  State<SocialSearchUserPage> createState() => _SocialSearchUserPageState();
}

class _SocialSearchUserPageState extends State<SocialSearchUserPage> {
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
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.brand900Variant,
        title: Text(
          'Buscar usuário',
          style: AppTextStyles.missionsSectionTitle.copyWith(
            color: AppColors.brand900Variant,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.action500),
                      )
                    : _results.isEmpty
                    ? Center(
                        child: Text(
                          'Sem resultados ainda.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final user = _results[index];
                          return SocialSearchResultItem(
                            user: user,
                            onAdd: !user.canSendRequest
                                ? null
                                : () async {
                                    await widget.onAddUser(user);
                                    if (!mounted) return;
                                    setState(() {
                                      _results[index] = SocialUserSearchResult(
                                        id: user.id,
                                        name: user.name,
                                        email: user.email,
                                        avatarUrl: user.avatarUrl,
                                        avatarFrameId: user.avatarFrameId,
                                        isFriend: false,
                                        friendRequestStatus: 'outgoing',
                                      );
                                    });
                                  },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
