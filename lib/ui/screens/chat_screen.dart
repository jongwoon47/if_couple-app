import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_locale_scope.dart';
import '../../models/app_user.dart';
import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../services/image_upload_prep.dart';
import '../../services/firebase_error_messages.dart';
import '../../services/translation_service.dart';
import '../widgets/fullscreen_network_image_viewer.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.appUser});

  final AppUser appUser;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final Map<String, String> _manualTranslations = <String, String>{};
  final Set<String> _translatingMessageIds = <String>{};

  bool _sending = false;

  /// 첫 로드 시 한 번 맨 아래로 (대화 화면 열었을 때)
  bool _hasScrolledToBottomOnce = false;

  /// 내가 메시지/사진 보낸 직후 스트림 반영 뒤 맨 아래로
  bool _forceScrollAfterSend = false;

  /// Firestore는 내림차순이라 [0]이 최신. 직전 빌드의 최신 ID (내 메시지 도착 시 맨 아래로)
  String? _prevNewestMessageId;

  /// 답장 대상 메시지 (입력창 위 미리보기용)
  ChatMessage? _replyTarget;

  /// 로컬 리액션 (messageId -> 이모지). 저장 안 함.
  final Map<String, String> _localReactions = <String, String>{};

  /// 채팅 리스트 맨 아래 (과거→최신 순이므로 maxScrollExtent)
  final ScrollController _chatScrollController = ScrollController();

  /// 답장 탭 시 해당 말풍선으로 스크롤 (이미 빌드된 행만)
  final Map<String, GlobalKey> _bubbleKeys = <String, GlobalKey>{};

  void _scrollToRepliedMessage(String? messageId) {
    if (messageId == null || messageId.isEmpty) return;
    final key = _bubbleKeys[messageId];
    final ctx = key?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.3,
    );
  }

  /// 리스트가 아직 붙지 않았거나 항목 높이가 잡히기 전에는 maxScrollExtent가 짧게 나올 수 있어
  /// 웹·iOS·Android 모두 지연·다음 프레임 재시도한다 (웹만 쓰면 모바일에서 맨 아래로 못 가는 경우가 있음).
  void _scrollToBottomWithRetry({int attempt = 0}) {
    if (!mounted) return;
    const maxAttempts = 50;
    void doJump() {
      if (!mounted || !_chatScrollController.hasClients) return;
      try {
        final pos = _chatScrollController.position;
        _chatScrollController.jumpTo(pos.maxScrollExtent);
      } catch (_) {
        if (attempt < maxAttempts) {
          Future<void>.delayed(const Duration(milliseconds: 50), () {
            _scrollToBottomWithRetry(attempt: attempt + 1);
          });
        }
      }
    }

    if (!_chatScrollController.hasClients) {
      if (attempt < maxAttempts) {
        Future<void>.delayed(const Duration(milliseconds: 50), () {
          _scrollToBottomWithRetry(attempt: attempt + 1);
        });
      }
      return;
    }
    doJump();
    // 다음 1~2프레임: 레이아웃 직후 extent 갱신
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      doJump();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        doJump();
      });
    });
    // 이미지·폰트 등으로 높이가 늦게 잡힐 때
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      doJump();
    });
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      doJump();
    });
  }

  /// 스트림 지연·이미지 레이아웃 후에도 맨 아래 유지
  void _scheduleScrollToBottomFollowUps() {
    for (final ms in const [400, 1000, 2200]) {
      Future<void>.delayed(Duration(milliseconds: ms), () {
        if (!mounted) return;
        _scrollToBottomWithRetry();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChatService.markChatAsRead(widget.appUser.userId);
    });
  }

  @override
  void dispose() {
    ChatService.markChatAsRead(widget.appUser.userId);
    _controller.dispose();
    _messageFocusNode.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _refocusMessageField() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_messageFocusNode);
      }
    });
  }

  /// 새 메시지가 도착하면 자동으로 읽음 처리
  void _markReadIfNewMessages(List<ChatMessage> messages) {
    if (messages.isEmpty) return;
    final newest = messages.first;
    if (newest.senderId != widget.appUser.userId) {
      ChatService.markChatAsRead(widget.appUser.userId);
    }
  }

  void _openAttachmentMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5E6EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Color(0xFFE98ABF),
                      size: 28,
                    ),
                  ),
                  title: Text(
                    l10n.camera,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(l10n.takePhoto),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromCamera();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5E6EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: Color(0xFFE98ABF),
                      size: 28,
                    ),
                  ),
                  title: Text(
                    l10n.gallery,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(l10n.pickPhotosMax5),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 72,
      );
      if (!mounted) return;
      if (xFile == null) return;
      final bytes = await xFile.readAsBytes();
      if (!mounted) return;
      await _sendImageMessage([bytes], [xFile.name]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.cameraOpenFailed(e.toString()),
          ),
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final list = await picker.pickMultiImage(
        limit: 5,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 72,
      );
      if (!mounted) return;
      if (list.isEmpty) return;
      final bytesList = <List<int>>[];
      final names = <String>[];
      for (final x in list) {
        final b = await x.readAsBytes();
        bytesList.add(b);
        names.add(x.name);
      }
      if (!mounted) return;
      await _sendImageMessage(bytesList, names);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.galleryOpenFailed(e.toString()),
          ),
        ),
      );
    }
  }

  Future<void> _sendImageMessage(
    List<List<int>> bytesList,
    List<String> fileNames,
  ) async {
    if (bytesList.isEmpty) return;
    setState(() => _sending = true);
    try {
      final prepared = await Future.wait(
        List.generate(
          bytesList.length,
          (i) => prepareImageForUpload(
            bytesList[i],
            fileNames[i],
            maxSide: 1600,
            quality: 72,
          ),
        ),
      );
      final uploadTasks = <Future<String>>[];
      for (var i = 0; i < prepared.length; i++) {
        final p = prepared[i];
        uploadTasks.add(
          ChatService.uploadChatImage(
            coupleId: widget.appUser.coupleId!,
            senderId: widget.appUser.userId,
            bytes: p.bytes,
            fileExtension: p.fileExtension,
          ),
        );
      }
      final urls = await Future.wait(uploadTasks);
      if (!mounted) return;
      await ChatService.sendMessage(
        coupleId: widget.appUser.coupleId!,
        senderId: widget.appUser.userId,
        text: '',
        imageUrls: urls,
      );
      if (!mounted) return;
      setState(() => _forceScrollAfterSend = true);
      // 사진 업로드가 길면 스트림 반영이 늦음 — 플래그를 충분히 유지
      Future<void>.delayed(const Duration(milliseconds: 4500), () {
        if (mounted) setState(() => _forceScrollAfterSend = false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.photoSentCount(urls.length),
          ),
        ),
      );
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[ChatScreen] 이미지 전송 오류: $e');
        // ignore: avoid_print
        print('[ChatScreen] 스택: $st');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messageForUploadFailure(e, AppLocalizations.of(context)!)),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _refocusMessageField();
      }
    }
  }

  Future<void> _send() async {
    if (_sending) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await ChatService.sendMessage(
        coupleId: widget.appUser.coupleId!,
        senderId: widget.appUser.userId,
        text: text,
        replyToMessageId: _replyTarget?.messageId,
        replyToText: _replyTarget?.messageText,
      );
      _controller.clear();
      if (!mounted) return;
      setState(() {
        _replyTarget = null;
        _forceScrollAfterSend = true;
      });
      Future<void>.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _forceScrollAfterSend = false);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanErrorMessage(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _refocusMessageField();
      }
    }
  }

  String _cleanErrorMessage(Object error) {
    var message = error.toString().trim();
    for (final prefix in const ['Exception: ', 'Error: ', 'FirebaseException: ']) {
      if (message.startsWith(prefix)) {
        message = message.substring(prefix.length).trim();
      }
    }
    if (message.isEmpty) {
      return AppLocaleController.l10n.messageSendFailed;
    }
    return message;
  }

  /// 날짜가 바뀌는 구간에 날짜 구분선을 넣은 목록 생성
  /// messageStream 이 createdAt 기준 내림차순(최신 → 과거)이라 그 순서를 그대로 사용한다.
  List<_ChatListEntry> _buildChatEntries(
    List<ChatMessage> messages,
    String currentUserId,
  ) {
    final entries = <_ChatListEntry>[];
    final now = DateTime.now();
    DateTime? currentGroupDate;

    for (final msg in messages) {
      // 방금 보낸 내 메시지(2분 이내)는 현재 시각 기준 날짜 사용
      final useDate = msg.senderId == currentUserId &&
              now.difference(msg.createdAt).inMinutes < 2
          ? now
          : msg.createdAt;
      final msgDate = DateTime(useDate.year, useDate.month, useDate.day);

      if (currentGroupDate == null) {
        currentGroupDate = msgDate;
      } else if (currentGroupDate != msgDate) {
        // 이전 날짜 그룹이 끝났으므로 그 날짜의 구분선을 추가
        entries.add(_ChatListEntry.date(currentGroupDate));
        currentGroupDate = msgDate;
      }

      entries.add(_ChatListEntry.message(msg));
    }

    // 마지막 날짜 그룹의 구분선 추가
    if (currentGroupDate != null) {
      entries.add(_ChatListEntry.date(currentGroupDate));
    }

    // 과거→최신 순(인덱스 0=가장 오래된 것)으로 바꿔서, 인덱스로 스크롤 시 오래된 메시지도 이동 가능
    return entries.reversed.toList();
  }

  String? _effectiveTranslatedText(ChatMessage message) {
    final saved = message.translatedText?.trim();
    if (saved != null && saved.isNotEmpty && saved != message.messageText) {
      return saved;
    }

    final manual = _manualTranslations[message.messageId];
    if (manual != null && manual.trim().isNotEmpty && manual.trim() != message.messageText) {
      return manual.trim();
    }

    return null;
  }

  /// 액션 시트의 「번역 보기」에서만 호출
  Future<void> _translateMessageFromSheet(ChatMessage message) async {
    final id = message.messageId;
    if (_translatingMessageIds.contains(id)) return;

    final existing = _effectiveTranslatedText(message);
    if (existing != null) return;

    if (message.messageText.trim().isEmpty) return;

    if (!TranslationService.isPrimaryConfigured) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translateServerNotConfigured),
        ),
      );
      return;
    }

    setState(() {
      _translatingMessageIds.add(id);
    });

    try {
      final translated = await TranslationService.translate(
        text: message.messageText,
        userId: widget.appUser.userId,
        systemPrompt: TranslationService.couplePrompt,
        retranslate: false,
      );
      if (!mounted) return;
      setState(() {
        _manualTranslations[id] = translated;
      });

      final coupleId = widget.appUser.coupleId;
      if (coupleId != null && coupleId.isNotEmpty) {
        ChatService.saveTranslation(
          coupleId: coupleId,
          messageId: id,
          translatedText: translated,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanErrorMessage(e))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _translatingMessageIds.remove(id);
        });
      }
    }
  }

  void _toggleReaction(ChatMessage message, String emoji) {
    setState(() {
      final current = _localReactions[message.messageId];
      if (current == emoji) {
        _localReactions.remove(message.messageId);
      } else {
        _localReactions[message.messageId] = emoji;
      }
    });
  }

  Future<void> _openMessageActions(ChatMessage message) async {
    final action = await showModalBottomSheet<_MessageAction>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ReactionChip(
                      label: '🥺',
                      onTap: () =>
                          Navigator.of(context).pop(_MessageAction.reactionSad),
                    ),
                    const SizedBox(width: 10),
                    _ReactionChip(
                      label: '👍',
                      onTap: () =>
                          Navigator.of(context).pop(_MessageAction.reactionLike),
                    ),
                    const SizedBox(width: 10),
                    _ReactionChip(
                      label: '✨',
                      onTap: () =>
                          Navigator.of(context).pop(_MessageAction.reactionSparkle),
                    ),
                    const SizedBox(width: 10),
                    _ReactionChip(
                      label: '💗',
                      onTap: () =>
                          Navigator.of(context).pop(_MessageAction.reactionHeart),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.reply_rounded),
                title: Text(l10n.reply),
                onTap: () => Navigator.of(context).pop(_MessageAction.reply),
              ),
              if (message.messageText.trim().isNotEmpty &&
                  _effectiveTranslatedText(message) == null)
                ListTile(
                  leading: const Icon(Icons.translate_rounded),
                  title: Text(l10n.showTranslation),
                  onTap: () =>
                      Navigator.of(context).pop(_MessageAction.viewTranslation),
                ),
              if (_effectiveTranslatedText(message) != null)
                ListTile(
                  leading: const Icon(Icons.refresh_rounded),
                  title: Text(l10n.retranslate),
                  onTap: () =>
                      Navigator.of(context).pop(_MessageAction.retranslate),
                ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: Text(l10n.copyOriginal),
                onTap: () =>
                    Navigator.of(context).pop(_MessageAction.copyOriginal),
              ),
              ListTile(
                leading: const Icon(Icons.content_copy_rounded),
                title: Text(l10n.copyTranslation),
                onTap: () =>
                    Navigator.of(context).pop(_MessageAction.copyTranslation),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: Text(
                  l10n.deleteMessage,
                  style: const TextStyle(
                    color: Color(0xFFB55C80),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () =>
                    Navigator.of(context).pop(_MessageAction.deleteMessage),
              ),
            ],
          ),
        );
      },
    );

    switch (action) {
      case _MessageAction.reply:
        setState(() {
          _replyTarget = message;
        });
        break;
      case _MessageAction.reactionSad:
        _toggleReaction(message, '🥺');
        break;
      case _MessageAction.reactionLike:
        _toggleReaction(message, '👍');
        break;
      case _MessageAction.reactionSparkle:
        _toggleReaction(message, '✨');
        break;
      case _MessageAction.reactionHeart:
        _toggleReaction(message, '💗');
        break;
      case _MessageAction.viewTranslation:
        await _translateMessageFromSheet(message);
        break;
      case _MessageAction.retranslate:
        await _retranslateMessage(message);
        break;
      case _MessageAction.copyOriginal:
        await Clipboard.setData(ClipboardData(text: message.messageText));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.messageCopied)),
        );
        break;
      case _MessageAction.copyTranslation:
        final toCopy = _effectiveTranslatedText(message) ?? message.messageText;
        await Clipboard.setData(ClipboardData(text: toCopy));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.translationCopied)),
        );
        break;
      case _MessageAction.deleteMessage:
        await _confirmDeleteMessage(message);
        break;
      case null:
        break;
    }
  }

  Future<void> _confirmDeleteMessage(ChatMessage message) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteMessageTitle),
        content: Text(l10n.deleteMessageConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Color(0xFFB55C80))),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ChatService.deleteMessage(
        coupleId: widget.appUser.coupleId!,
        messageId: message.messageId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.deleteMessageDone)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanErrorMessage(e))),
      );
    }
  }

  Future<void> _retranslateMessage(ChatMessage message) async {
    final id = message.messageId;
    if (_translatingMessageIds.contains(id)) return;

    if (!TranslationService.isRetranslateConfigured) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.retranslateServerNotConfigured),
        ),
      );
      return;
    }

    setState(() {
      _translatingMessageIds.add(id);
    });

    try {
      final translated = await TranslationService.translate(
        text: message.messageText,
        userId: widget.appUser.userId,
        systemPrompt: TranslationService.couplePrompt,
        retranslate: true,
      );
      if (!mounted) return;
      setState(() {
        _manualTranslations[id] = translated;
      });

      final coupleId = widget.appUser.coupleId;
      if (coupleId != null && coupleId.isNotEmpty) {
        ChatService.saveTranslation(
          coupleId: coupleId,
          messageId: id,
          translatedText: translated,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanErrorMessage(e))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _translatingMessageIds.remove(id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chatTitle),
        backgroundColor: const Color(0xFFF7E9F8),
        elevation: 0,
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7E9F8), Color(0xFFEEDCF3)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: ChatService.messageStream(widget.appUser.coupleId!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!;
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(l10n.chatEmpty),
                    );
                  }

                  _markReadIfNewMessages(messages);

                  final entries = _buildChatEntries(
                    messages,
                    widget.appUser.userId,
                  );
                  final messageIds = <String>{};
                  for (final e in entries) {
                    if (e.message != null) {
                      messageIds.add(e.message!.messageId);
                    }
                  }
                  _bubbleKeys.removeWhere((id, _) => !messageIds.contains(id));

                  final effectiveTranslatedText = _effectiveTranslatedText;
                  final translatingIds = _translatingMessageIds;

                  // messageStream: 내림차순 → 최신이 [0]
                  final newest = messages.first;
                  final newestId = newest.messageId;
                  final newestChanged = _prevNewestMessageId != null &&
                      newestId != _prevNewestMessageId;
                  final ownNewestArrived = newestChanged &&
                      newest.senderId == widget.appUser.userId;
                  final partnerNewestArrived = newestChanged &&
                      newest.senderId != widget.appUser.userId;
                  _prevNewestMessageId = newestId;

                  // 맨 아래: (1) 처음 입장 (2) 전송 직후 플래그 (3) 내/상대 최신 메시지가 스트림에 반영된 뒤
                  final scrollToBottomNow = entries.isNotEmpty &&
                      (!_hasScrolledToBottomOnce ||
                          _forceScrollAfterSend ||
                          ownNewestArrived ||
                          partnerNewestArrived);
                  if (scrollToBottomNow) {
                    final markFirstDone = !_hasScrolledToBottomOnce;
                    // 새 메시지(내 것·상대 것) 반영 후 레이아웃·이미지 로드에 맞춰 재스크롤
                    final followUpAfterNewMessage =
                        ownNewestArrived || partnerNewestArrived;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _scrollToBottomWithRetry();
                      // jumpTo 직후 같은 프레임에서 setState 하면 리스트가 다시 그려지며
                      // 스크롤이 맨 위로 튈 수 있음 → 스크롤 다음 프레임에만 갱신
                      if (markFirstDone) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() => _hasScrolledToBottomOnce = true);
                          }
                        });
                      }
                      if (followUpAfterNewMessage) {
                        _scheduleScrollToBottomFollowUps();
                      }
                    });
                  }

                  return _ChatMessagesListView(
                    key: ValueKey(widget.appUser.coupleId ?? 'chat'),
                    scrollController: _chatScrollController,
                    entries: entries,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      if (entry.isDateSeparator) {
                        return _DateSeparator(date: entry.date!);
                      }
                      final msg = entry.message!;
                      final mine = msg.senderId == widget.appUser.userId;
                      final bubbleKey =
                          _bubbleKeys.putIfAbsent(msg.messageId, GlobalKey.new);
                      return _MessageBubble(
                        key: bubbleKey,
                        message: msg,
                        mine: mine,
                        translatedText: effectiveTranslatedText(msg),
                        isTranslating: translatingIds.contains(msg.messageId),
                        reaction: _localReactions[msg.messageId],
                        onLongPress: () => _openMessageActions(msg),
                        onReplyTap: _scrollToRepliedMessage,
                      );
                    },
                  );
                },
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyTarget != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5E6EC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.reply_rounded,
                            size: 18,
                            color: Color(0xFFE98ABF),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _replyTarget!.messageText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF7A627F),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _replyTarget = null;
                              });
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: Color(0xFFB39ABF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      IconButton(
                        onPressed: _openAttachmentMenu,
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        iconSize: 28,
                        color: const Color(0xFFE98ABF),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _messageFocusNode,
                          readOnly: _sending,
                          textInputAction: TextInputAction.send,
                          onTap: () => _scrollToBottomWithRetry(),
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: l10n.messageHint,
                          ),
                          maxLines: 3,
                          minLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// 리스트 항목: 날짜 구분선 또는 메시지
/// [StreamBuilder]가 스트림마다 자식을 새로 그려도 [ScrollController]는 부모에 있고,
/// [ListView]만 이 State 아래에 두어 스크롤 위치가 유지되도록 한다.
class _ChatMessagesListView extends StatefulWidget {
  const _ChatMessagesListView({
    super.key,
    required this.scrollController,
    required this.entries,
    required this.itemBuilder,
  });

  final ScrollController scrollController;
  final List<_ChatListEntry> entries;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  State<_ChatMessagesListView> createState() => _ChatMessagesListViewState();
}

class _ChatMessagesListViewState extends State<_ChatMessagesListView> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.entries.length,
      itemBuilder: widget.itemBuilder,
    );
  }
}

class _ChatListEntry {
  const _ChatListEntry._({this.date, this.message})
      : assert(date != null || message != null);

  factory _ChatListEntry.date(DateTime d) =>
      _ChatListEntry._(date: d);

  factory _ChatListEntry.message(ChatMessage m) =>
      _ChatListEntry._(message: m);

  final DateTime? date;
  final ChatMessage? message;
  bool get isDateSeparator => date != null;
}

/// 날짜 구분선: ---2026년 2월 14일---
class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final text = DateFormat.yMMMd(lang).format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          '---$text---',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF8E8395),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// 메시지 시간 (로케일에 맞는 오전/오후·표기)
String _formatMessageTime(BuildContext context, DateTime date) {
  final tod = TimeOfDay.fromDateTime(date);
  return MaterialLocalizations.of(context).formatTimeOfDay(
    tod,
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5E6EC),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(label, style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }
}

/// 원본 비율·크기에 맞춤(최대 가로 280 / 세로 520, 작은 이미지는 확대 안 함). 고정 큰 박스 없이 빈 여백 최소화.
class _ChatNetworkImageFitted extends StatefulWidget {
  const _ChatNetworkImageFitted({required this.url});

  final String url;

  static const double maxW = 280;
  static const double maxH = 520;

  @override
  State<_ChatNetworkImageFitted> createState() => _ChatNetworkImageFittedState();
}

class _ChatNetworkImageFittedState extends State<_ChatNetworkImageFitted> {
  double? _w;
  double? _h;
  ImageStream? _imageStream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _listenImageSize();
  }

  @override
  void didUpdateWidget(_ChatNetworkImageFitted oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _detachListener();
      setState(() {
        _w = null;
        _h = null;
      });
      _listenImageSize();
    }
  }

  void _detachListener() {
    final s = _imageStream;
    final l = _listener;
    if (s != null && l != null) {
      s.removeListener(l);
    }
    _imageStream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _detachListener();
    super.dispose();
  }

  void _listenImageSize() {
    final provider = NetworkImage(widget.url);
    final stream = provider.resolve(const ImageConfiguration());
    _imageStream = stream;
    _listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        final iw = info.image.width.toDouble();
        final ih = info.image.height.toDouble();
        _detachListener();
        if (iw <= 0 || ih <= 0) {
          if (!mounted) return;
          setState(() {
            _w = _ChatNetworkImageFitted.maxW;
            _h = 120;
          });
          return;
        }
        var scale = (_ChatNetworkImageFitted.maxW / iw).clamp(0.0, double.infinity);
        final sh = _ChatNetworkImageFitted.maxH / ih;
        if (sh < scale) scale = sh;
        if (scale > 1) scale = 1;
        if (!mounted) return;
        setState(() {
          _w = iw * scale;
          _h = ih * scale;
        });
      },
      onError: (_, __) {
        _detachListener();
        if (!mounted) return;
        setState(() {
          _w = _ChatNetworkImageFitted.maxW;
          _h = 120;
        });
      },
    );
    stream.addListener(_listener!);
  }

  @override
  Widget build(BuildContext context) {
    if (_w == null || _h == null) {
      return SizedBox(
        width: _ChatNetworkImageFitted.maxW,
        height: 120,
        child: const Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Image.network(
      widget.url,
      width: _w,
      height: _h,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => SizedBox(
        width: _ChatNetworkImageFitted.maxW,
        height: 120,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.mine,
    required this.translatedText,
    required this.isTranslating,
    this.reaction,
    required this.onLongPress,
    this.onReplyTap,
  });

  final ChatMessage message;
  final bool mine;
  final String? translatedText;
  final bool isTranslating;
  final String? reaction;
  final VoidCallback onLongPress;
  final void Function(String? messageId)? onReplyTap;

  static const double _kChatImageMaxWidth = 280;

  @override
  Widget build(BuildContext context) {
    final translated = translatedText?.trim();
    final hasTranslated = translated != null && translated.isNotEmpty && translated != message.messageText;
    final hasReply = message.replyToText != null &&
        message.replyToText!.trim().isNotEmpty;
    final imageUrls = message.imageUrls ?? const <String>[];
    final hasImages = imageUrls.isNotEmpty;
    final hasText = message.messageText.trim().isNotEmpty;
    // 사진만 보낸 메시지: 말풍선 없이 원본 비율 그대로
    final isImageOnly = hasImages && !hasText && !hasReply;

    Widget timeRow() => Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _formatMessageTime(context, message.createdAt),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            if (reaction != null && reaction!.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(reaction!, style: const TextStyle(fontSize: 14)),
            ],
          ],
        );

    final imageColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: imageUrls
          .map(
            (url) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FullscreenNetworkImageViewer.show(context, url),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isImageOnly ? 12 : 8),
                  child: _ChatNetworkImageFitted(url: url),
                ),
              ),
            ),
          )
          .toList(),
    );

    if (isImageOnly) {
      return Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            constraints: const BoxConstraints(maxWidth: _kChatImageMaxWidth),
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                imageColumn,
                const SizedBox(height: 4),
                timeRow(),
              ],
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          constraints: const BoxConstraints(maxWidth: _kChatImageMaxWidth),
          decoration: BoxDecoration(
            color: mine
                ? const Color(0xFFFFC9E0)
                : const Color(0xFFFDF3FA),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x20E98ABF),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasReply) ...[
                GestureDetector(
                  onTap: message.replyToMessageId != null
                      ? () => onReplyTap?.call(message.replyToMessageId)
                      : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x1A000000),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (message.replyToMessageId != null)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.reply_rounded,
                              size: 14,
                              color: Color(0xFF8E8395),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            message.replyToText!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6E5F7A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              if (hasImages) ...[
                imageColumn,
                if (hasText) const SizedBox(height: 6),
              ],
              if (hasText) Text(message.messageText),
              if (hasTranslated) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x1FFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    translated,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6E5F7A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (isTranslating) ...[
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context)!.translating,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8395),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              timeRow(),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MessageAction {
  reply,
  reactionSad,
  reactionLike,
  reactionSparkle,
  reactionHeart,
  viewTranslation,
  retranslate,
  copyOriginal,
  copyTranslation,
  deleteMessage,
}
