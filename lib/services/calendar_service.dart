import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/couple_event.dart';

class CalendarService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _eventRef(String coupleId) {
    return _firestore.collection('couples').doc(coupleId).collection('events');
  }

  static Stream<List<CoupleEvent>> eventStream(String coupleId) {
    return _eventRef(coupleId)
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(CoupleEvent.fromDoc).toList());
  }

  static Future<void> createEvent({
    required String coupleId,
    required String title,
    required String description,
    required DateTime date,
  }) async {
    final ref = _eventRef(coupleId).doc();
    await ref.set({
      'eventId': ref.id,
      'coupleId': coupleId,
      'title': title.trim(),
      'description': description.trim(),
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateEvent({
    required String coupleId,
    required String eventId,
    required String title,
    required String description,
    required DateTime date,
  }) async {
    await _eventRef(coupleId).doc(eventId).update({
      'title': title.trim(),
      'description': description.trim(),
      'date': Timestamp.fromDate(date),
    });
  }

  static Future<void> deleteEvent({
    required String coupleId,
    required String eventId,
  }) async {
    await _eventRef(coupleId).doc(eventId).delete();
  }

  /// 여행 일정을 캘린더에 자동 등록 (시작일~종료일 각각 이벤트 생성)
  static Future<void> syncTripToCalendar({
    required String coupleId,
    required String tripId,
    required String tripTitle,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final batch = _firestore.batch();
    var current = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final totalDays = end.difference(current).inDays + 1;
    int dayNum = 1;

    while (!current.isAfter(end)) {
      final ref = _eventRef(coupleId).doc();
      final period =
          '${startDate.month.toString().padLeft(2, '0')}.'
          '${startDate.day.toString().padLeft(2, '0')}'
          ' - '
          '${endDate.month.toString().padLeft(2, '0')}.'
          '${endDate.day.toString().padLeft(2, '0')}';
      batch.set(ref, {
        'eventId': ref.id,
        'coupleId': coupleId,
        'title': '✈️ $tripTitle',
        'description': 'Day $dayNum/$totalDays  ($period)',
        'date': Timestamp.fromDate(current),
        'tripId': tripId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      current = current.add(const Duration(days: 1));
      dayNum++;
    }
    await batch.commit();
  }

  /// 특정 여행에 연결된 캘린더 이벤트 일괄 삭제
  static Future<void> removeTripEvents({
    required String coupleId,
    required String tripId,
  }) async {
    final snapshot = await _eventRef(coupleId)
        .where('tripId', isEqualTo: tripId)
        .get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
