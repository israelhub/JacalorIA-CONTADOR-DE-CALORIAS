import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/files/bytes_file_saver.dart';
import '../../../core/config/api_config.dart';
import '../../../core/images/widget_image_exporter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_confirm_modal.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../../shared/widgets/app_section_header.dart';
import 'social_create_group_page.dart';
import 'social_friend_profile_page.dart';
import '../widgets/social_invite_group_friends_dialog.dart';
import '../helpers/social_group_helpers.dart';
import '../models/social_group_models.dart';
import '../services/social_service.dart';
import '../widgets/social_activity_item.dart';
import '../widgets/social_group_result_share_card.dart';
import '../widgets/social_ranking_item.dart';

class SocialGroupDetailPage extends StatefulWidget {
  const SocialGroupDetailPage({
    super.key,
    required this.groupId,
    this.initialDetail,
    SocialService? service,
  }) : _service = service ?? const SocialService();

  final String groupId;
  final SocialGroupDetail? initialDetail;
  final SocialService _service;

  @override
  State<SocialGroupDetailPage> createState() => _SocialGroupDetailPageState();
}

class _SocialGroupDetailPageState extends State<SocialGroupDetailPage> {
  SocialGroupDetail? _detail;
  bool _isLoading = true;
  String? _errorMessage;
  _ExportAction? _exportingAction;
  bool _isLeavingGroup = false;
  bool _isDeletingGroup = false;
  bool _isInvitingFriends = false;
  String? _removingMemberUserId;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackScreen(
      'social_group_detail',
      properties: {'group_id': widget.groupId},
    );
    _detail = widget.initialDetail;
    _isLoading = _detail == null;
    if (_detail == null) {
      _loadDetail();
    }
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await widget._service.fetchGroup(widget.groupId);
      if (!mounted) {
        return;
      }

      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _openMemberProfile(SocialRankingEntry entry) async {
    if (entry.userId.trim().isEmpty) return;

    await context.pushSlidePage<void>(
      SocialFriendProfilePage(
        friendId: entry.userId,
        initialFriendName: entry.name,
        groupId: widget.groupId,
        service: widget._service,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.action500),
      );
    }

    if (_errorMessage != null || _detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage ?? 'Não foi possível carregar o grupo.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: 'Tentar novamente', onPressed: _loadDetail),
            ],
          ),
        ),
      );
    }

    final detail = _detail!;
    final group = detail.group;
    final isFinished = group.remainingDays <= 0;
    SocialRankingEntry? currentUserEntry;
    for (final entry in detail.ranking) {
      if (entry.isCurrentUser) {
        currentUserEntry = entry;
        break;
      }
    }
    final isCurrentUserLeader = currentUserEntry?.isLeader == true;
    final canLeaveGroup = currentUserEntry != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.brand900Variant,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  group.name,
                  style: AppTextStyles.homeSectionTitle.copyWith(
                    color: AppColors.brand900Variant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCurrentUserLeader) ...[
                GestureDetector(
                  onTap: (_isLeavingGroup || _isDeletingGroup) ? null : _openEditGroupSheet,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.settings_outlined,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              GestureDetector(
                onTap: canLeaveGroup && !_isLeavingGroup ? _leaveGroup : null,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: _isLeavingGroup
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.textSecondary),
                        )
                      : Icon(
                          Icons.logout_rounded,
                          color: canLeaveGroup ? AppColors.textSecondary : AppColors.textMuted,
                          size: 22,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.performanceCardBorder,
                width: 2,
              ),
              boxShadow: AppShadows.performanceCard,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: socialIconBackgroundColor(),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    socialGroupIconData(group.iconKey),
                    size: 30,
                    color: AppColors.action500,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: AppTextStyles.homeSectionTitle.copyWith(
                          color: AppColors.brand900Variant,
                        ),
                      ),
                      if (group.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          group.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _LabelPill(
                            label: group.competitionLabel,
                            foreground: AppColors.action500,
                            background: AppColors.missionsXpPill,
                          ),
                          _LabelPill(
                            label: group.durationDaysLabel,
                            foreground: AppColors.textMuted,
                            background: AppColors.surfaceAlt,
                          ),
                          _LabelPill(
                            label: group.remainingDaysLabel,
                            foreground: AppColors.missionsRewardGold,
                            background: AppColors.missionsGoldPill,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: _isInvitingFriends ? 'Carregando amigos...' : 'Convidar amigos',
            variant: AppButtonVariant.outline,
            leadingIcon: Icons.person_add_alt_1_rounded,
            onPressed: _isInvitingFriends ? null : _openInviteFriendsModal,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (isFinished) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.missionsGoldPill,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.performanceCardBorder, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag_rounded, color: AppColors.missionsRewardGold, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Parabéns! Vocês concluiram o desafio, veja abaixo o ranking final e compartilhe ou baixe o resultado.',
                      style: AppTextStyles.captionStrong.copyWith(
                        color: AppColors.brand900Variant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppSectionHeader(
            title: 'Ranking',
            titleStyle: AppTextStyles.missionsSectionTitle.copyWith(
              color: AppColors.brand900Variant,
            ),
            trailing: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.accent500,
              size: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.performanceCardBorder,
                width: 2,
              ),
              boxShadow: AppShadows.performanceCard,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Column(
                children: [
                  for (final entry in detail.ranking)
                    SocialRankingItem(
                      entry: entry,
                      competitionType: detail.group.competitionType,
                      onTap: () => _openMemberProfile(entry),
                      onRemove: isCurrentUserLeader &&
                              !entry.isCurrentUser &&
                              !entry.isLeader
                          ? () => _removeMember(entry)
                          : null,
                      isRemoving: _removingMemberUserId == entry.userId,
                    ),
                ],
              ),
            ),
          ),
          if (isFinished) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: _exportingAction == _ExportAction.download ? 'Baixando...' : 'Baixar resultado',
                    variant: AppButtonVariant.outline,
                    onPressed: _exportingAction == null ? _downloadRankingJpg : null,
                    leadingIcon: Icons.download_rounded,
                    textStyle: AppTextStyles.socialResultAction,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: _exportingAction == _ExportAction.share ? 'Compartilhando...' : 'Compartilhar',
                    onPressed: _exportingAction == null ? _shareRankingJpg : null,
                    leadingIcon: Icons.ios_share_rounded,
                    textStyle: AppTextStyles.socialResultAction.copyWith(color: AppColors.surface),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(
            title: 'Atividade recente',
            titleStyle: AppTextStyles.missionsSectionTitle.copyWith(
              color: AppColors.brand900Variant,
            ),
            trailing: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.action500,
              size: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Column(
            children: [
              for (final activity in detail.recentActivities) ...[
                SocialActivityItemWidget(activity: activity),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openEditGroupSheet() async {
    if (_detail == null) {
      return;
    }
    SocialRankingEntry? currentUserEntry;
    for (final entry in _detail!.ranking) {
      if (entry.isCurrentUser) {
        currentUserEntry = entry;
        break;
      }
    }
    final isCurrentUserLeader = currentUserEntry?.isLeader == true;

    final result = await context.pushSlidePage<SocialGroupDetail>(
      SocialCreateGroupPage(
        service: widget._service,
        existingGroup: _detail!.group,
        onDeleteRequested: isCurrentUserLeader ? _deleteGroup : null,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _detail = result;
    });
  }

  Future<void> _leaveGroup() async {
    final shouldLeave = await AppConfirmModal.show(
      context,
      title: 'Sair do grupo',
      message: 'Tem certeza que deseja sair deste grupo?',
      confirmLabel: 'Sair',
      cancelLabel: 'Cancelar',
      isDanger: true,
    );
    if (!shouldLeave || !mounted) return;

    setState(() => _isLeavingGroup = true);
    try {
      await widget._service.leaveGroup(widget.groupId);
      if (!mounted) return;
      AppToast.show(context, message: 'Você saiu do grupo');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      AppToast.show(context, message: error.toString().replaceFirst('Exception: ', ''), isError: true);
      setState(() => _isLeavingGroup = false);
    }
  }

  Future<void> _removeMember(SocialRankingEntry entry) async {
    if (_removingMemberUserId != null) return;

    final shouldRemove = await AppConfirmModal.show(
      context,
      title: 'Excluir membro',
      message: 'Remover ${entry.name} deste grupo?',
      confirmLabel: 'Excluir',
      cancelLabel: 'Cancelar',
      isDanger: true,
    );
    if (!shouldRemove || !mounted) return;

    setState(() => _removingMemberUserId = entry.userId);
    try {
      final updated = await widget._service.removeGroupMember(
        groupId: widget.groupId,
        memberUserId: entry.userId,
      );
      if (!mounted) return;
      setState(() {
        _detail = updated;
        _removingMemberUserId = null;
      });
      AppToast.show(context, message: '${entry.name} foi removido do grupo');
    } catch (error) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
      setState(() => _removingMemberUserId = null);
    }
  }

  Future<void> _deleteGroup() async {
    if (_isDeletingGroup) return;

    final shouldDelete = await AppConfirmModal.show(
      context,
      title: 'Excluir grupo',
      message: 'Essa ação é permanente. Deseja excluir este grupo?',
      confirmLabel: 'Excluir',
      cancelLabel: 'Cancelar',
      isDanger: true,
    );
    if (!shouldDelete || !mounted) return;

    setState(() => _isDeletingGroup = true);
    try {
      await widget._service.deleteGroup(widget.groupId);
      if (!mounted) return;
      AppToast.show(context, message: 'Grupo excluído com sucesso');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      AppToast.show(context, message: error.toString().replaceFirst('Exception: ', ''), isError: true);
      setState(() => _isDeletingGroup = false);
    }
  }

  Future<void> _openInviteFriendsModal() async {
    if (_detail == null || _isInvitingFriends) {
      return;
    }

    setState(() => _isInvitingFriends = true);
    try {
      final friendsData = await widget._service.fetchFriends();
      if (!mounted || _detail == null) return;

      final groupUserIds = _detail!.ranking.map((entry) => entry.userId).toSet();
      final selectedFriendIds = await showDialog<List<String>>(
        context: context,
        builder: (context) => SocialInviteGroupFriendsDialog(
          friends: friendsData.friends,
          excludedUserIds: groupUserIds,
          onShareLink: _shareGroupInviteLink,
          onCopyId: _copyGroupInviteCode,
        ),
      );

      if (!mounted || selectedFriendIds == null || selectedFriendIds.isEmpty) return;

      final updated = await widget._service.addGroupMembers(
        groupId: widget.groupId,
        memberUserIds: selectedFriendIds,
      );
      if (!mounted) return;
      setState(() {
        _detail = updated;
      });
      AppToast.show(context, message: 'Amigos adicionados ao grupo');
    } catch (error) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isInvitingFriends = false);
    }
  }

  String _groupInviteCode() {
    return _detail?.group.inviteCode?.trim().toUpperCase() ?? '';
  }

  String _groupInviteLink() {
    final code = _groupInviteCode();
    return '${ApiConfig.shareBaseUrl}/group?code=$code';
  }

  Future<void> _shareGroupInviteLink() async {
    final code = _groupInviteCode();
    if (code.isEmpty) {
      if (!mounted) return;
      AppToast.show(context, message: 'ID do grupo indisponível', isError: true);
      return;
    }
    await Share.share(_groupInviteLink());
  }

  Future<void> _copyGroupInviteCode() async {
    final code = _groupInviteCode();
    if (code.isEmpty) {
      if (!mounted) return;
      AppToast.show(context, message: 'ID do grupo indisponível', isError: true);
      return;
    }
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    AppToast.show(context, message: 'ID do grupo copiado');
  }

  String _resultJpgFilename() {
    final groupName = (_detail?.group.name ?? 'grupo')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return 'ranking-final-$groupName-${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  Future<Uint8List> _buildResultJpgBytes() async {
    final detail = _detail!;
    // Warm brand fonts so accents ("Sequência") rasterize correctly.
    await GoogleFonts.pendingFonts([
      GoogleFonts.baloo2(),
      GoogleFonts.nunito(),
    ]);
    final logicalSize = SocialGroupResultShareCard.measureLogicalSize(detail);
    return exportWidgetToImageBytes(
      widget: SocialGroupResultShareCard(detail: detail),
      logicalSize: logicalSize,
      pixelRatio: 2,
      asJpeg: true,
      jpegQuality: 92,
    );
  }

  Future<void> _downloadRankingJpg() async {
    if (_exportingAction != null) return;
    setState(() => _exportingAction = _ExportAction.download);
    try {
      final bytes = await _buildResultJpgBytes();
      await saveBytesToDownloads(
        bytes: bytes,
        filename: _resultJpgFilename(),
        mimeType: 'image/jpeg',
      );
      if (!mounted) return;
      AppToast.show(
        context,
        message: kIsWeb ? 'Download iniciado' : 'Imagem salva com sucesso',
      );
    } catch (error) {
      if (!mounted) return;
      AppToast.show(context, message: error.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _exportingAction = null);
    }
  }

  Future<void> _shareRankingJpg() async {
    if (_exportingAction != null) return;
    setState(() => _exportingAction = _ExportAction.share);
    try {
      final bytes = await _buildResultJpgBytes();
      final filename = _resultJpgFilename();
      final shareText = 'Resultado final do grupo ${_detail?.group.name ?? ''}';

      if (kIsWeb) {
        try {
          await Share.shareXFiles(
            [XFile.fromData(bytes, mimeType: 'image/jpeg', name: filename)],
            text: shareText,
          );
        } catch (_) {
          await saveBytesToDownloads(
            bytes: bytes,
            filename: filename,
            mimeType: 'image/jpeg',
          );
          if (!mounted) return;
          AppToast.show(
            context,
            message: 'Compartilhamento indisponível. Imagem baixada.',
          );
        }
      } else {
        final path = await writeBytesToTempForSharing(bytes: bytes, filename: filename);
        await Share.shareXFiles(
          [XFile(path)],
          text: shareText,
        );
      }
    } catch (error) {
      if (!mounted) return;
      AppToast.show(context, message: error.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _exportingAction = null);
    }
  }
}

enum _ExportAction {
  download,
  share,
}

class _LabelPill extends StatelessWidget {
  const _LabelPill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionStrong.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
