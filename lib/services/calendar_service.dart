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
}
