import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../shared/services/supabase_storage_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_confirm_modal.dart';
import '../../../shared/widgets/app_page_route.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../auth/service/auth_service.dart';
import '../../food_analysis/helpers/image_optimizer.dart';
import '../models/jaca_emoji_catalog.dart';
import '../models/social_group_chat_message.dart';
import '../helpers/social_group_helpers.dart';
import '../services/social_service.dart';
import '../widgets/chat_ime_slide.dart';
import '../widgets/jaca_emoji_picker.dart';
import '../widgets/social_group_chat_appear.dart';
import '../widgets/social_group_chat_bubble.dart';
import '../widgets/social_group_chat_composer.dart';
import '../widgets/social_group_chat_message_actions.dart';
import 'social_friend_profile_page.dart';

class SocialGroupChatPage extends StatefulWidget {
  const SocialGroupChatPage({
    super.key,
    required this.groupId,
    required this.groupName,
    SocialService? service,
    ImagePicker? imagePicker,
  }) : _service = service ?? const SocialService(),
       _imagePicker = imagePicker;

  final String groupId;
  final String groupName;
  final SocialService _service;
  final ImagePicker? _imagePicker;

  @override
  State<SocialGroupChatPage> createState() => _SocialGroupChatPageState();
}

class _SocialGroupChatPageState extends State<SocialGroupChatPage> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final List<SocialGroupChatMessage> _messages = [];
  final Set<String> _appearedMessageIds = <String>{};

  bool _isLoading = true;
  bool _isSending = false;
  bool _showEmojiPicker = false;
  bool _hasSeededMessages = false;
  Set<String> _ownedStickerIds = const <String>{};
  String? _errorMessage;
  Timer? _pollTimer;
  SocialGroupChatMessage? _replyingTo;
  SocialGroupChatMessage? _editingMessage;

  ImagePicker get _imagePicker => widget._imagePicker ?? ImagePicker();

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.trackScreen(
      'social_group_chat',
      properties: {'group_id': widget.groupId},
    );
    _ownedStickerIds = JacaEmojiCatalog.purchasedIdsFromProfile(
      AuthService.globalUser,
    );
    _loadMessages();
    unawaited(_loadOwnedStickers());
    _focusNode.addListener(_onComposerFocusChange);
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      unawaited(_pollNewMessages());
    });
  }

  Future<void> _loadOwnedStickers() async {
    try {
      final profile = await AuthService().fetchProfile();
      if (!mounted) return;
      setState(() {
        _ownedStickerIds = JacaEmojiCatalog.purchasedIdsFromProfile(profile);
      });
    } catch (_) {}
  }

  void _onComposerFocusChange() {
    if (_focusNode.hasFocus && _showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _focusNode.removeListener(_onComposerFocusChange);
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = _messages.isEmpty;
      _errorMessage = null;
    });
    try {
      final messages = await widget._service.fetchGroupMessages(widget.groupId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(messages);
        _isLoading = false;
        _seedAppearedMessages();
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (_messages.isEmpty) {
          _errorMessage = error.toString().replaceFirst('Exception: ', '');
        }
      });
    }
  }

  void _seedAppearedMessages() {
    if (_hasSeededMessages) return;
    _appearedMessageIds.addAll(_messages.map((message) => message.id));
    _hasSeededMessages = true;
  }

  bool _shouldAnimateMessage(String id) {
    return _hasSeededMessages && !_appearedMessageIds.contains(id);
  }

  void _markMessageAppeared(String id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appearedMessageIds.add(id);
    });
  }

  Future<void> _pollNewMessages() async {
    if (_isLoading || _isSending) return;
    try {
      final latest = await widget._service.fetchGroupMessages(widget.groupId);
      if (!mounted || _isSameMessageSnapshot(latest)) return;
      final previousLastId = _messages.isEmpty ? null : _messages.last.id;
      final nextLastId = latest.isEmpty ? null : latest.last.id;
      setState(() {
        _messages
          ..clear()
          ..addAll(latest);
        _syncComposerWithMessages();
      });
      if (nextLastId != null && nextLastId != previousLastId) {
        _scrollToBottom(animated: true);
      }
    } catch (_) {}
  }

  void _scrollToBottom({bool animated = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(0);
      }
    });
  }

  SocialGroupChatMessage? _messageById(String id) {
    final index = _messages.indexWhere((message) => message.id == id);
    return index < 0 ? null : _messages[index];
  }

  bool _isSameMessageSnapshot(List<SocialGroupChatMessage> latest) {
    if (latest.length != _messages.length) return false;
    for (var i = 0; i < latest.length; i++) {
      final current = _messages[i];
      final incoming = latest[i];
      if (current.id != incoming.id ||
          current.body != incoming.body ||
          current.imageUrl != incoming.imageUrl ||
          current.isDeleted != incoming.isDeleted ||
          current.editedAt != incoming.editedAt ||
          current.replyTo?.id != incoming.replyTo?.id ||
          current.reactionsSignature != incoming.reactionsSignature) {
        return false;
      }
    }
    return true;
  }

  void _replaceMessage(SocialGroupChatMessage updated) {
    final index = _messages.indexWhere((message) => message.id == updated.id);
    if (index < 0) {
      _messages.add(updated);
      return;
    }
    _messages[index] = updated;
  }

  void _syncComposerWithMessages() {
    if (_editingMessage != null) {
      final current = _messageById(_editingMessage!.id);
      if (current == null || !current.canEdit) {
        _editingMessage = null;
        _textController.clear();
      } else {
        _editingMessage = current;
      }
    }
    if (_replyingTo != null) {
      final current = _messageById(_replyingTo!.id);
      if (current == null || !current.canReply) {
        _replyingTo = null;
      } else {
        _replyingTo = current;
      }
    }
  }

  void _cancelComposerMode() {
    setState(() {
      _replyingTo = null;
      _editingMessage = null;
    });
  }

  void _startReply(SocialGroupChatMessage message) {
    setState(() {
      if (_editingMessage != null) {
        _textController.clear();
      }
      _editingMessage = null;
      _replyingTo = message;
      _showEmojiPicker = false;
    });
    _focusNode.requestFocus();
  }

  void _startEdit(SocialGroupChatMessage message) {
    setState(() {
      _replyingTo = null;
      _editingMessage = message;
      _showEmojiPicker = false;
      _textController.text = message.body ?? '';
      _textController.selection = TextSelection.collapsed(
        offset: _textController.text.length,
      );
    });
    _focusNode.requestFocus();
  }

  Future<void> _openSenderProfile(SocialGroupChatMessage message) async {
    if (message.userId.trim().isEmpty || message.isCurrentUser) return;
    await context.pushSlidePage<void>(
      SocialFriendProfilePage(
        friendId: message.userId,
        initialFriendName: message.senderName,
        groupId: widget.groupId,
        service: widget._service,
      ),
    );
  }

  Future<void> _onMessageAction(
    SocialGroupChatMessage message,
    SocialGroupChatMessageAction action,
  ) async {
    switch (action) {
      case SocialGroupChatMessageAction.reply:
        _startReply(message);
      case SocialGroupChatMessageAction.edit:
        _startEdit(message);
      case SocialGroupChatMessageAction.delete:
        await _confirmDelete(message);
      case SocialGroupChatMessageAction.view:
        final url = message.imageUrl?.trim() ?? '';
        if (url.isNotEmpty) {
          await openSocialGroupChatImage(context, url);
        }
    }
  }

  Future<void> _reactToMessage(
    SocialGroupChatMessage message,
    String emojiId,
  ) async {
    if (!message.canReact) return;
    try {
      final updated = await widget._service.reactToGroupMessage(
        groupId: widget.groupId,
        messageId: message.id,
        emojiId: emojiId,
      );
      if (!mounted) return;
      setState(() => _replaceMessage(updated));
    } catch (error) {
      if (!mounted) return;
      AppToast.error(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _confirmDelete(SocialGroupChatMessage message) async {
    final shouldDelete = await AppConfirmModal.show(
      context,
      title: 'Excluir mensagem',
      message: 'Essa mensagem some para todo o grupo. Quer excluir?',
      confirmLabel: 'Excluir',
      cancelLabel: 'Cancelar',
      isDanger: true,
    );
    if (!shouldDelete || !mounted) return;

    setState(() => _isSending = true);
    try {
      final updated = await widget._service.deleteGroupMessage(
        groupId: widget.groupId,
        messageId: message.id,
      );
      if (!mounted) return;
      setState(() {
        _replaceMessage(updated);
        if (_editingMessage?.id == message.id) {
          _editingMessage = null;
          _textController.clear();
        }
        if (_replyingTo?.id == message.id) {
          _replyingTo = null;
        }
        _isSending = false;
      });
    } catch (error) {
      if (!mounted) return;
      AppToast.error(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
      setState(() => _isSending = false);
    }
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;
    if (_editingMessage != null) {
      await _saveEdit(text);
      return;
    }
    _textController.clear();
    await _send(type: 'text', body: text);
  }

  Future<void> _saveEdit(String text) async {
    final editing = _editingMessage;
    if (editing == null) return;
    setState(() => _isSending = true);
    try {
      final updated = await widget._service.editGroupMessage(
        groupId: widget.groupId,
        messageId: editing.id,
        body: text,
      );
      if (!mounted) return;
      _textController.clear();
      setState(() {
        _replaceMessage(updated);
        _editingMessage = null;
        _isSending = false;
      });
    } catch (error) {
      if (!mounted) return;
      AppToast.error(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
      setState(() => _isSending = false);
    }
  }

  Future<void> _sendEmoji(JacaEmojiItem emoji) async {
    if (_isSending || _editingMessage != null) return;
    setState(() => _showEmojiPicker = false);
    await _send(type: 'emoji', body: emoji.id);
  }

  Future<void> _pickAndSendImage() async {
    if (_isSending) return;
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (picked == null) return;

    setState(() => _isSending = true);
    try {
      final original = await picked.readAsBytes();
      final optimized = await optimizeForAnalysis(original);
      final uploadedUrl = await SupabaseStorageService.uploadGroupChatImage(
        optimized.bytes,
        extension: '.jpg',
      );
      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        throw Exception('Não foi possível enviar a imagem.');
      }
      await _send(type: 'image', imageUrl: uploadedUrl, alreadySending: true);
    } catch (error) {
      if (!mounted) return;
      AppToast.error(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
      setState(() => _isSending = false);
    }
  }

  Future<void> _send({
    required String type,
    String? body,
    String? imageUrl,
    bool alreadySending = false,
  }) async {
    if (!alreadySending) {
      setState(() => _isSending = true);
    }
    try {
      final sent = await widget._service.sendGroupMessage(
        groupId: widget.groupId,
        type: type,
        body: body,
        imageUrl: imageUrl,
        replyToId: _replyingTo?.id,
      );
      if (!mounted) return;
      final exists = _messages.any((message) => message.id == sent.id);
      setState(() {
        if (!exists) _messages.add(sent);
        _replyingTo = null;
        _isSending = false;
      });
      _scrollToBottom(animated: true);
    } catch (error) {
      if (!mounted) return;
      if (type == 'text' &&
          (body ?? '').isNotEmpty &&
          _textController.text.trim().isEmpty) {
        _textController.text = body!;
      }
      AppToast.error(
        context,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          const ChatViewPadding(top: true),
          _buildHeader(),
          Expanded(
            child: ClipRect(
              child: ChatKeyboardLift(
                child: Column(
                  children: [
                    Expanded(child: _buildMessages()),
                    _buildStickerPanel(),
                    _buildComposerContext(),
                    SocialGroupChatComposer(
                      controller: _textController,
                      focusNode: _focusNode,
                      enabled: !_isSending,
                      isEditing: _editingMessage != null,
                      showEmojiPicker: _showEmojiPicker,
                      onToggleEmoji: _toggleEmojiPicker,
                      onPickImage: _pickAndSendImage,
                      onSend: _sendText,
                    ),
                    const ChatViewPadding(top: false),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
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
              widget.groupName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.homeSectionTitle.copyWith(
                color: AppColors.brand900Variant,
              ),
            ),
          ),
          const Icon(
            Icons.chat_bubble_rounded,
            color: AppColors.action500,
            size: 22,
          ),
        ],
      ),
    );
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
      return;
    }
    _focusNode.unfocus();
    setState(() => _showEmojiPicker = true);
  }

  Widget _buildMessages() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.action500),
      );
    }

    if (_errorMessage != null && _messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Text(
            'Ainda não tem mensagens.\nManda um oi para o grupo!',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: ListView.builder(
        reverse: true,
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        addAutomaticKeepAlives: false,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final messageIndex = _messages.length - 1 - index;
          final message = _messages[messageIndex];
          final previous = messageIndex > 0 ? _messages[messageIndex - 1] : null;
          final next = messageIndex < _messages.length - 1
              ? _messages[messageIndex + 1]
              : null;
          final cluster = socialChatCluster(
            userId: message.userId,
            previousUserId: previous?.userId,
            nextUserId: next?.userId,
          );
          final animate = _shouldAnimateMessage(message.id);
          if (animate) _markMessageAppeared(message.id);
          return SocialGroupChatAppear(
            key: ValueKey('group-chat-appear-${message.id}'),
            animate: animate,
            isMine: message.isCurrentUser,
            child: SocialGroupChatBubble(
              message: message,
              ownedStickerIds: _ownedStickerIds,
              showAvatar: cluster.showAvatar,
              showSenderName: cluster.showSenderName,
              isLastInGroup: cluster.isLastInGroup,
              onAction: (action) => _onMessageAction(message, action),
              onReact: (emojiId) => _reactToMessage(message, emojiId),
              onAvatarTap: message.isCurrentUser
                  ? null
                  : () => _openSenderProfile(message),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStickerPanel() {
    if (!_showEmojiPicker) return const SizedBox.shrink();
    return JacaEmojiPicker(
      key: const ValueKey('jaca-sticker-panel'),
      ownedIds: _ownedStickerIds,
      onSelected: _sendEmoji,
    );
  }

  Widget _buildComposerContext() {
    final editing = _editingMessage;
    final reply = _replyingTo;
    if (editing == null && reply == null) {
      return const SizedBox.shrink();
    }

    final isEdit = editing != null;
    final title = isEdit
        ? 'Editando mensagem'
        : 'Respondendo a ${reply!.senderName}';
    final subtitle = isEdit ? null : reply!.preview;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: SocialChatQuoteFrame(
        key: ValueKey(
          isEdit ? 'group-chat-edit-banner' : 'group-chat-reply-banner',
        ),
        backgroundColor: AppColors.surfaceAlt,
        trailing: IconButton(
          onPressed: _isSending
              ? null
              : () {
                  if (isEdit) _textController.clear();
                  _cancelComposerMode();
                },
          icon: const Icon(
            Icons.close_rounded,
            color: AppColors.brand900Variant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionStrong.copyWith(
                color: AppColors.brand900,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
