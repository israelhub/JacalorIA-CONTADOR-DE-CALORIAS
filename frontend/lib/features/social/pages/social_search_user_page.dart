import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_back_page_header.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_form_card.dart';
import '../../../shared/widgets/app_skeleton.dart';
import '../../home/widgets/home_shell_layout.dart';
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
  bool _hasSearched = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results.clear();
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _searching = true;
      _hasSearched = true;
    });
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
      backgroundColor: AppColors.pageBackground,
      extendBodyBehindAppBar: true,
      appBar: const AppBackPageHeader(title: 'Buscar usuário'),
      body: AppBackPageContent(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.lg,
            AppSpacing.pageHorizontal,
            homeShellScrollBottomInset(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _queryController,
                      textInputAction: TextInputAction.search,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ex.: joao123, e-mail ou nome',
                        hintStyle: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.insetSurface,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.md,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(
                            color: AppColors.inputBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(
                            color: AppColors.inputBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(
                            color: AppColors.inputBorder,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _runSearch(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(label: 'Buscar usuário', onPressed: _runSearch),
                  ],
                ),
              ),
              if (_searching || _hasSearched) ...[
                const SizedBox(height: AppSpacing.cardGap),
                AppFormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Resultados obtidos',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.brand900Variant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (_searching)
                        const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppSkeletonFriendRow(),
                            SizedBox(height: AppSpacing.sm),
                            AppSkeletonFriendRow(),
                            SizedBox(height: AppSpacing.sm),
                            AppSkeletonFriendRow(),
                          ],
                        )
                      else if (_results.isEmpty)
                        Text(
                          'Nenhum usuário encontrado.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        for (var index = 0; index < _results.length; index++) ...[
                          if (index > 0) const SizedBox(height: AppSpacing.sm),
                          SocialSearchResultItem(
                            user: _results[index],
                            onAdd: !_results[index].canSendRequest
                                ? null
                                : () async {
                                    final user = _results[index];
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
                          ),
                        ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
