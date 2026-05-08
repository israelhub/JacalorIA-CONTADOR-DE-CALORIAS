import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config/api_config.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_confirm_modal.dart';
import '../../../shared/widgets/app_section_header.dart';
import '../widgets/social_create_group_sheet.dart';
import '../widgets/social_invite_group_friends_dialog.dart';
import '../helpers/social_group_helpers.dart';
import '../models/social_group_models.dart';
import '../services/social_service.dart';
import '../widgets/social_activity_item.dart';
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

  @override
  void initState() {
    super.initState();
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
                      const SizedBox(height: 2),
                      Text(
                        group.description,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
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
                  for (final entry in detail.ranking) SocialRankingItem(entry: entry),
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

    final result = await showModalBottomSheet<SocialGroupDetail>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SocialCreateGroupSheet(
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
      AppToast.show(context, message: error.toString().replaceFirst('Exception: ', ''), icon: Icons.error_outline_rounded);
      setState(() => _isLeavingGroup = false);
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
      AppToast.show(context, message: error.toString().replaceFirst('Exception: ', ''), icon: Icons.error_outline_rounded);
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
        icon: Icons.error_outline_rounded,
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
      AppToast.show(context, message: 'ID do grupo indisponível', icon: Icons.error_outline_rounded);
      return;
    }
    await Share.share(_groupInviteLink());
  }

  Future<void> _copyGroupInviteCode() async {
    final code = _groupInviteCode();
    if (code.isEmpty) {
      if (!mounted) return;
      AppToast.show(context, message: 'ID do grupo indisponível', icon: Icons.error_outline_rounded);
      return;
    }
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    AppToast.show(context, message: 'ID do grupo copiado');
  }

  Future<File> _writeJpgFile() async {
    final bytes = await _buildResultJpgBytes();
    final groupName = (_detail?.group.name ?? 'grupo')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final file = File(
      '${(await _resolveDownloadsDirectory()).path}${Platform.pathSeparator}ranking-final-$groupName-${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<Uint8List> _buildResultJpgBytes() async {
    final detail = _detail!;
    final groupName = detail.group.name.trim().isEmpty ? 'Grupo' : detail.group.name.trim();
    final ranking = detail.ranking;
    final width = 1080;
    final headerHeight = 220;
    final rowHeight = 110;
    final bodyPadding = 56;
    final rankBlockHeight = 60 + (ranking.length * rowHeight) + 30;
    final height = headerHeight + rankBlockHeight + bodyPadding;
    final canvas = img.Image(width: width, height: height);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 253));

    img.fillRect(canvas, x1: 32, y1: 28, x2: width - 32, y2: headerHeight - 24, color: img.ColorRgb8(238, 247, 230));
    img.drawRect(canvas, x1: 32, y1: 28, x2: width - 32, y2: headerHeight - 24, color: img.ColorRgb8(212, 236, 196), thickness: 3);
    img.drawString(
      canvas,
      'Resultado final do grupo',
      font: img.arial24,
      x: 58,
      y: 54,
      color: img.ColorRgb8(25, 54, 41),
    );
    img.drawString(
      canvas,
      groupName,
      font: img.arial48,
      x: 58,
      y: 84,
      color: img.ColorRgb8(30, 81, 62),
    );
    img.drawString(
      canvas,
      'Parabens aos vencedores.',
      font: img.arial24,
      x: 58,
      y: 142,
      color: img.ColorRgb8(77, 101, 89),
    );

    try {
      final mascotData = await rootBundle.load('assets/images/Jaca_acenando_v2.webp');
      final mascotDecoded = img.decodeImage(mascotData.buffer.asUint8List());
      if (mascotDecoded != null) {
        final mascot = img.copyResize(mascotDecoded, width: 180);
        img.compositeImage(canvas, mascot, dstX: width - 240, dstY: 30);
      }
    } catch (_) {}

    final blockTop = headerHeight + 8;
    img.fillRect(canvas, x1: 32, y1: blockTop, x2: width - 32, y2: height - 32, color: img.ColorRgb8(255, 255, 253));
    img.drawRect(canvas, x1: 32, y1: blockTop, x2: width - 32, y2: height - 32, color: img.ColorRgb8(239, 227, 215), thickness: 3);

    var y = blockTop + 20;
    for (final entry in ranking) {
      final isCurrent = entry.isCurrentUser;
      if (isCurrent) {
        img.fillRect(canvas, x1: 40, y1: y - 6, x2: width - 40, y2: y + rowHeight - 16, color: img.ColorRgb8(238, 247, 230));
      }

      img.drawString(
        canvas,
        '${entry.position}',
        font: img.arial24,
        x: 62,
        y: y + 20,
        color: img.ColorRgb8(77, 101, 89),
      );
      img.drawString(
        canvas,
        entry.name,
        font: img.arial24,
        x: 132,
        y: y + 20,
        color: img.ColorRgb8(25, 54, 41),
      );
      img.drawString(
        canvas,
        '${entry.streakDays} sequencia',
        font: img.arial24,
        x: width - 320,
        y: y + 20,
        color: img.ColorRgb8(240, 138, 36),
      );
      y += rowHeight;
      img.drawLine(canvas, x1: 48, y1: y - 18, x2: width - 48, y2: y - 18, color: img.ColorRgb8(244, 244, 240));
    }

    return Uint8List.fromList(img.encodeJpg(canvas, quality: 92));
  }

  Future<Directory> _resolveDownloadsDirectory() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
    final picked = await getDownloadsDirectory();
    if (picked != null) {
      if (!picked.existsSync()) {
        await picked.create(recursive: true);
      }
      return picked;
    }
    final fallback = Directory('${Directory.systemTemp.path}${Platform.pathSeparator}downloads');
    if (!fallback.existsSync()) {
      await fallback.create(recursive: true);
    }
    return fallback;
  }

  Future<void> _downloadRankingJpg() async {
    if (_exportingAction != null) return;
    setState(() => _exportingAction = _ExportAction.download);
    try {
      await _writeJpgFile();
      if (!mounted) return;
      AppToast.show(context, message: 'Imagem salva com sucesso');
    } catch (error) {
      if (!mounted) return;
      AppToast.show(context, message: error.toString().replaceFirst('Exception: ', ''), icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _exportingAction = null);
    }
  }

  Future<void> _shareRankingJpg() async {
    if (_exportingAction != null) return;
    setState(() => _exportingAction = _ExportAction.share);
    try {
      final file = await _writeJpgFile();
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Resultado final do grupo ${_detail?.group.name ?? ''}',
      );
    } catch (error) {
      if (!mounted) return;
      AppToast.show(context, message: error.toString().replaceFirst('Exception: ', ''), icon: Icons.error_outline_rounded);
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
