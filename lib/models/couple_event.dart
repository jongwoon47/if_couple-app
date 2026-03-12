import 'package:cloud_firestore/cloud_firestore.dart';

class CoupleEvent {
  const CoupleEvent({
    required this.eventId,
    required this.coupleId,
    required this.title,
    required this.description,
    required this.date,
    this.createdAt,
  });

  final String eventId;
  final String coupleId;
  final String title;
  final String description;
  final DateTime date;
  final DateTime? createdAt;

  /// 자동 생성된 연간 일정(처음만난날·생일)이면 true (수정/삭제 불가)
  bool get isAnnual => eventId.startsWith('annual:');

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'coupleId': coupleId,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
    };
  }

  factory CoupleEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? <String, dynamic>{};
    return CoupleEvent(
      eventId: doc.id,
      coupleId: (map['coupleId'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      date: ((map['date'] as Timestamp?) ?? Timestamp.now()).toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
