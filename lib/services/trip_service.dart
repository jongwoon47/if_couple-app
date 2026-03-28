import 'package:cloud_firestore/cloud_firestore.dart';

import 'calendar_service.dart';
import '../models/trip_models.dart';

class TripService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _tripRef(String coupleId) {
    return _firestore.collection('couples').doc(coupleId).collection('trips');
  }

  static CollectionReference<Map<String, dynamic>> _planRef(
    String coupleId,
    String tripId,
  ) {
    return _tripRef(coupleId).doc(tripId).collection('plans');
  }

  static Stream<List<Trip>> tripStream(String coupleId) {
    return _tripRef(coupleId)
        .orderBy('startDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Trip.fromDoc).toList());
  }

  static Stream<List<Plan>> planStream({
    required String coupleId,
    required String tripId,
  }) {
    // 날짜만 orderBy (복합 인덱스 불필요). 같은 날 순서는 time으로 클라이언트 정렬.
    return _planRef(coupleId, tripId)
        .orderBy('date')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map(Plan.fromDoc).toList();
      list.sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        if (a.time == null && b.time == null) return 0;
        if (a.time == null) return 1;
        if (b.time == null) return -1;
        return a.time!.compareTo(b.time!);
      });
      return list;
    });
  }

  static Future<String> createTrip({
    required String coupleId,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final ref = _tripRef(coupleId).doc();
    final trip = Trip(
      id: ref.id,
      coupleId: coupleId,
      title: title.trim(),
      startDate: startDate,
      endDate: endDate,
    );
    await ref.set(trip.toJson()..['createdAt'] = FieldValue.serverTimestamp());
    await CalendarService.syncTripToCalendar(
      coupleId: coupleId,
      tripId: ref.id,
      tripTitle: trip.title,
      startDate: trip.startDate,
      endDate: trip.endDate,
    );
    return ref.id;
  }

  static Future<void> deleteTrip({
    required String coupleId,
    required String tripId,
  }) async {
    // 캘린더 연동 일정/세부일정(plans) 삭제 후 trip 삭제
    await CalendarService.removeTripEvents(coupleId: coupleId, tripId: tripId);
    final plansSnapshot = await _planRef(coupleId, tripId).get();
    final batch = _firestore.batch();
    for (final doc in plansSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_tripRef(coupleId).doc(tripId));
    await batch.commit();
  }

  static Future<void> upsertPlan({
    required String coupleId,
    required Plan plan,
  }) async {
    final ref = _planRef(coupleId, plan.tripId).doc(plan.id);
    await ref.set(plan.toJson()..['createdAt'] = FieldValue.serverTimestamp());
  }

  static Future<void> deletePlan({
    required String coupleId,
    required String tripId,
    required String planId,
  }) async {
    await _planRef(coupleId, tripId).doc(planId).delete();
  }
}

