import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../models/app_user.dart';
import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import '../../services/translation_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.appUser});

  final AppUser appUser;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final Map<String, String> _manualTranslations = <String, String>{};
  final Set<String> _translatingMessageIds = <String>{};

  bool _sending = false;
  int _lastEntriesLength = 0;

  /// 답장 대상 메시지 (입력창 위 미리보기용)
  ChatMessage? _replyTarget;

  /// 로컬 리액션 (messageId -> 이모지). 저장 안 함.
  final Map<String, String> _localReactions = <String, String>{};

  /// 인덱스 기반 스크롤 (아주 오래된 메시지도 답장 시 이동 가능)
  final ItemScrollController _itemScrollController = ItemScrollController();
  /// messageId → 리스트 인덱스 (빌드 시 채움)
  final Map<String, int> _messageIdToIndex = <String, int>{};

  void _scrollToRepliedMessage(String? messageId) {
    if (messageId == null || messageId.isEmpty) return;
    final index = _messageIdToIndex[messageId];
    if (index == null || !_itemScrollController.isAttached) return;
    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.3,
    );
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
    _controller.dispose();
    super.dispose();
  }

  void _openAttachmentMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
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
                title: const Text(
                  '카메라',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: const Text('사진 촬영'),
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
                title: const Text(
                  '갤러리',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: const Text('사진 선택, 최대 5장'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (!mounted) return;
      if (xFile == null) return;
      final bytes = await xFile.readAsBytes();
      if (!mounted) return;
      await _sendImageMessage([bytes], [xFile.name]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('카메라를 열 수 없어요. $e')),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final list = await picker.pickMultiImage(limit: 5, imageQuality: 85);
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
        SnackBar(content: Text('갤러리를 열 수 없어요. $e')),
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
      final urls = <String>[];
      for (var i = 0; i < bytesList.length; i++) {
        final ext = _imageExtensionFromPath(fileNames[i]);
        final url = await ChatService.uploadChatImage(
          coupleId: widget.appUser.coupleId!,
          senderId: widget.appUser.userId,
          bytes: bytesList[i],
          fileExtension: ext,
        );
        urls.add(url);
      }
      if (!mounted) return;
      await ChatService.sendMessage(
        coupleId: widget.appUser.coupleId!,
        senderId: widget.appUser.userId,
        text: '',
        imageUrls: urls,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 ${urls.length}장을 보냈어요.')),
      );
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[ChatScreen] 이미지 전송 오류: $e');
        // ignore: avoid_print
        print('[ChatScreen] 스택: $st');
      }
      if (!mounted) return;
      final msg = _imageErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 5)),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  String _imageExtensionFromPath(String path) {
    final parts = path.split('.');
    final ext = parts.length > 1 ? parts.last.toLowerCase() : '';
    if (ext == 'png' || ext == 'gif' || ext == 'webp' || ext == 'jpeg') {
      return ext;
    }
    return 'jpg';
  }

  String _imageErrorMessage(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'unauthenticated':
          return '로그인이 필요해요. 다시 로그인해 주세요.';
        case 'permission-denied':
          return '저장소 권한이 없어요. Firebase Storage 규칙을 확인해 주세요.';
        case 'canceled':
          return '업로드가 취소되었어요.';
        default:
          break;
      }
      final m = (error.message ?? error.code).trim();
      if (m.isNotEmpty && m.length < 120) {
        final suffix = kIsWeb
            ? '\n\n(웹에서는 Storage CORS 설정이 필요할 수 있어요.)'
            : '';
        return '이미지 전송에 실패했어요. $m$suffix';
      }
    }
    final suffix = kIsWeb
        ? '\n\n웹: Firebase 콘솔 → Storage → CORS 설정을 확인해 주세요.'
        : '';
    return '이미지 전송에 실패했어요. 다시 시도해 주세요.$suffix';
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
        systemPrompt: TranslationService.couplePrompt,
        replyToMessageId: _replyTarget?.messageId,
        replyToText: _replyTarget?.messageText,
      );
      _controller.clear();
      setState(() {
        _replyTarget = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanErrorMessage(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
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
      return '메시지 전송에 실패했어요. 다시 시도해 주세요.';
    }
    return message;
  }

  /// 날짜가 바뀌는 구간에 날짜 구분선을 넣은 목록 생성
  /// messageStream 이 createdAt 기준 내림차순(최신 → 과거)이라 그 순서를 그대로 사용한다.
  List<_ChatListEntry> _buildChatEntries(
    List<ChatMessage> messages,
    String currentUserId,
    DateTime? partnerLastReadAt,
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
    final manual = _manualTranslations[message.messageId];
    if (manual != null && manual.trim().isNotEmpty) {
      return manual.trim();
    }

    final saved = message.translatedText?.trim();
    if (saved == null || saved.isEmpty) {
      return null;
    }
    return saved;
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
                title: const Text('답장하기'),
                onTap: () => Navigator.of(context).pop(_MessageAction.reply),
              ),
              ListTile(
                leading: const Icon(Icons.translate_rounded),
                title: const Text('번역 보기'),
                onTap: () =>
                    Navigator.of(context).pop(_MessageAction.viewTranslation),
              ),
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: const Text('재번역'),
                onTap: () =>
                    Navigator.of(context).pop(_MessageAction.retranslate),
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('원문 복사'),
                onTap: () =>
                    Navigator.of(context).pop(_MessageAction.copyOriginal),
              ),
              ListTile(
                leading: const Icon(Icons.content_copy_rounded),
                title: const Text('번역본 복사'),
                onTap: () =>
                    Navigator.of(context).pop(_MessageAction.copyTranslation),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('메시지 삭제', style: TextStyle(color: Color(0xFFB55C80), fontWeight: FontWeight.w600)),
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
        await _showTranslation(message: message, forceRefresh: false);
        break;
      case _MessageAction.retranslate:
        await _showTranslation(message: message, forceRefresh: true);
        break;
      case _MessageAction.copyOriginal:
        await Clipboard.setData(ClipboardData(text: message.messageText));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('메시지를 복사했어요.')),
        );
        break;
      case _MessageAction.copyTranslation:
        final toCopy = _effectiveTranslatedText(message) ?? message.messageText;
        await Clipboard.setData(ClipboardData(text: toCopy));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('번역본을 복사했어요.')),
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('메시지 삭제'),
        content: const Text('이 메시지를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Color(0xFFB55C80))),
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
        const SnackBar(content: Text('메시지를 삭제했어요.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanErrorMessage(e))),
      );
    }
  }

  Future<void> _showTranslation({
    required ChatMessage message,
    required bool forceRefresh,
  }) async {
    final messageId = message.messageId;
    final cached = _effectiveTranslatedText(message);

    if (!forceRefresh && cached != null && cached != message.messageText) {
      await _showTranslationDialog(message.messageText, cached);
      return;
    }

    if (!TranslationService.isConfigured) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '번역 서버가 설정되지 않았어요. 실행 시 TRANSLATE_API_URL을 지정해 주세요.',
          ),
        ),
      );
      return;
    }

    if (_translatingMessageIds.contains(messageId)) return;

    setState(() {
      _translatingMessageIds.add(messageId);
    });

    try {
      final translated = await TranslationService.translate(
        text: message.messageText,
        userId: widget.appUser.userId,
        systemPrompt: TranslationService.couplePrompt,
      );
      if (!mounted) return;

      setState(() {
        _manualTranslations[messageId] = translated;
      });

      await _showTranslationDialog(message.messageText, translated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanErrorMessage(e))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _translatingMessageIds.remove(messageId);
        });
      }
    }
  }

  Future<void> _showTranslationDialog(String original, String translated) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('번역 보기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '원문',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(original),
              const SizedBox(height: 14),
              const Text(
                '번역',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(translated),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('대화'),
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
              child: StreamBuilder<DateTime?>(
                stream: ChatService.partnerLastReadAtStream(
                widget.appUser.coupleId!,
                widget.appUser.userId,
                ),
                builder: (context, readSnap) {
                final partnerLastReadAt = readSnap.data;
                return StreamBuilder<List<ChatMessage>>(
                  stream: ChatService.messageStream(widget.appUser.coupleId!),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data!;
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text('아직 메시지가 없어요. 첫 인사를 보내보세요.'),
                      );
                    }

                    final entries = _buildChatEntries(
                      messages,
                      widget.appUser.userId,
                      partnerLastReadAt,
                    );
                    _messageIdToIndex.clear();
                    for (var i = 0; i < entries.length; i++) {
                      final e = entries[i];
                      if (e.message != null) {
                        _messageIdToIndex[e.message!.messageId] = i;
                      }
                    }
                    final effectiveTranslatedText = _effectiveTranslatedText;
                    final translatingIds = _translatingMessageIds;

                    if (entries.length != _lastEntriesLength && entries.isNotEmpty) {
                      _lastEntriesLength = entries.length;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted || !_itemScrollController.isAttached) return;
                        final lastIndex = entries.length - 1;
                        if (lastIndex >= 0) {
                          _itemScrollController.scrollTo(
                            index: lastIndex,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            alignment: 1.0,
                          );
                        }
                      });
                    }

                    return ScrollablePositionedList.builder(
                      itemScrollController: _itemScrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: entries.length,
                      initialScrollIndex: entries.isEmpty ? 0 : entries.length - 1,
                      initialAlignment: 1.0,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        if (entry.isDateSeparator) {
                          return _DateSeparator(date: entry.date!);
                        }
                        final msg = entry.message!;
                        final mine = msg.senderId == widget.appUser.userId;
                        return _MessageBubble(
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
                          enabled: !_sending,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: const InputDecoration(
                            hintText: '메시지를 입력하세요...',
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
    final text = DateFormat('y년 M월 d일').format(date);
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

/// 메시지 시간만 표시 (오전 8:16 형식)
String _formatMessageTime(DateTime date) {
  final h = date.hour;
  final m = date.minute;
  final isPm = h >= 12;
  final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
  final ampm = isPm ? '오후' : '오전';
  return '$ampm $hour12:${m.toString().padLeft(2, '0')}';
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
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

  @override
  Widget build(BuildContext context) {
    final translated = translatedText?.trim();
    final hasTranslated = translated != null && translated.isNotEmpty && translated != message.messageText;
    final hasReply = message.replyToText != null &&
        message.replyToText!.trim().isNotEmpty;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          constraints: const BoxConstraints(maxWidth: 280),
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
              if (message.imageUrls != null && message.imageUrls!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: message.imageUrls!
                        .map((url) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                width: 280,
                                height: 200,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                  width: 280,
                                  height: 120,
                                  child: Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                if (message.messageText.isNotEmpty) const SizedBox(height: 6),
              ],
              if (message.messageText.isNotEmpty) Text(message.messageText),
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
                const Text(
                  '번역 중...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8395),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _formatMessageTime(message.createdAt),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  if (reaction != null && reaction!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(reaction!, style: const TextStyle(fontSize: 14)),
                  ],
                ],
              ),
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
