import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/chat_message.dart';
import 'app_firebase_storage.dart';
import 'translation_service.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static FirebaseStorage get _storage => getAppFirebaseStorage();

  static CollectionReference<Map<String, dynamic>> _messagesRef(String coupleId) {
    return _firestore.collection('couples').doc(coupleId).collection('messages');
  }

  static CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// 채팅 화면 진입 시 호출: 현재 사용자의 마지막 읽은 시각 갱신
  static Future<void> markChatAsRead(String userId) async {
    await _users.doc(userId).set({
      'lastReadChatAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 안 읽은 메시지 개수 스트림 (상대가 보낸 메시지 중 내가 아직 읽지 않은 것)
  static Stream<int> unreadCountStream(
    String coupleId,
    String currentUserId,
    String partnerId,
  ) {
    final controller = StreamController<int>.broadcast(sync: true);
    DateTime? lastReadAt;
    List<ChatMessage>? messages;
    void emit() {
      if (messages == null) return;
      final last = lastReadAt;
      final count = messages!
          .where((m) =>
              m.senderId == partnerId &&
              (last == null || m.createdAt.isAfter(last)))
          .length;
      controller.add(count);
    }

    final sub1 = _users.doc(currentUserId).snapshots().listen((snap) {
      final t = snap.data()?['lastReadChatAt'];
      lastReadAt = t != null ? (t as Timestamp).toDate() : null;
      emit();
    });
    final sub2 = _messagesRef(coupleId).snapshots().listen((snap) {
      messages = snap.docs.map(ChatMessage.fromDoc).toList();
      emit();
    });
    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };
    return controller.stream;
  }

  static Stream<List<ChatMessage>> messageStream(String coupleId) {
    return _messagesRef(coupleId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ChatMessage.fromDoc).toList());
  }

  /// 채팅 이미지를 Storage에 업로드하고 다운로드 URL 반환
  static Future<String> uploadChatImage({
    required String coupleId,
    required String senderId,
    required List<int> bytes,
    String fileExtension = 'jpg',
  }) async {
    final name =
        '${DateTime.now().millisecondsSinceEpoch}_${senderId.hashCode.abs()}'
            .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final path = 'couples/$coupleId/images/$name.$fileExtension';
    final ref = _storage.ref().child(path);
    final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    // jpg → image/jpeg (표준 MIME). 그 외는 image/확장자
    final contentType = fileExtension == 'jpg'
        ? 'image/jpeg'
        : 'image/$fileExtension';
    await ref.putData(
      data,
      SettableMetadata(contentType: contentType),
    );
    return ref.getDownloadURL();
  }

  static Future<void> sendMessage({
    required String coupleId,
    required String senderId,
    required String text,
    String? systemPrompt,
    String? replyToMessageId,
    String? replyToText,
    List<String>? imageUrls,
  }) async {
    final trimmed = text.trim();
    final hasImages =
        imageUrls != null && imageUrls.isNotEmpty;
    if (trimmed.isEmpty && !hasImages) return;

    String? translated;
    if (trimmed.isNotEmpty && TranslationService.isConfigured) {
      try {
        if (trimmed.length <= TranslationService.maxCharacters) {
          translated = await TranslationService.translate(
            text: trimmed,
            userId: senderId,
            systemPrompt: systemPrompt,
          );
        }
      } catch (_) {}
    }

    final ref = _messagesRef(coupleId).doc();
    await ref.set({
      'messageId': ref.id,
      'coupleId': coupleId,
      'senderId': senderId,
      'messageText': trimmed,
      'translatedText': translated,
      if (replyToMessageId != null && replyToMessageId.isNotEmpty)
        'replyToMessageId': replyToMessageId,
      if (replyToText != null && replyToText.isNotEmpty)
        'replyToText': replyToText,
      if (hasImages) 'imageUrls': imageUrls,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 메시지 삭제 (couples/{coupleId}/messages/{messageId})
  static Future<void> deleteMessage({
    required String coupleId,
    required String messageId,
  }) async {
    await _messagesRef(coupleId).doc(messageId).delete();
  }
}
