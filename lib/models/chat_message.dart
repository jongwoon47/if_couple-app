import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  const ChatMessage({
    required this.messageId,
    required this.coupleId,
    required this.senderId,
    required this.messageText,
    this.translatedText,
    this.replyToMessageId,
    this.replyToText,
    this.imageUrls,
    required this.createdAt,
  });

  final String messageId;
  final String coupleId;
  final String senderId;
  final String messageText;
  final String? translatedText;

  /// 답장 대상 메시지 ID (있을 때만 사용)
  final String? replyToMessageId;

  /// 답장 대상 메시지의 내용 (간단 미리보기용)
  final String? replyToText;

  /// 이미지 메시지일 때 Storage URL 목록 (최대 5장)
  final List<String>? imageUrls;

  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'coupleId': coupleId,
      'senderId': senderId,
      'messageText': messageText,
      'translatedText': translatedText,
      'replyToMessageId': replyToMessageId,
      'replyToText': replyToText,
      'imageUrls': imageUrls,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? <String, dynamic>{};
    final rawTranslated = (map['translatedText'] as String?)?.trim();
    final rawUrls = map['imageUrls'];
    List<String>? imageUrls;
    if (rawUrls is List) {
      imageUrls = rawUrls
          .map((e) => e?.toString().trim())
          .where((s) => s != null && s.isNotEmpty)
          .cast<String>()
          .toList();
      if (imageUrls.isEmpty) imageUrls = null;
    }

    return ChatMessage(
      messageId: doc.id,
      coupleId: (map['coupleId'] ?? '') as String,
      senderId: (map['senderId'] ?? '') as String,
      messageText: (map['messageText'] ?? '') as String,
      translatedText:
          (rawTranslated == null || rawTranslated.isEmpty) ? null : rawTranslated,
      replyToMessageId: (map['replyToMessageId'] as String?)?.trim(),
      replyToText: (map['replyToText'] as String?)?.trim(),
      imageUrls: imageUrls,
      createdAt: ((map['createdAt'] as Timestamp?) ?? Timestamp.now()).toDate(),
    );
  }
}
