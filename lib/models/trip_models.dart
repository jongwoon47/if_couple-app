import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  Trip({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.startDate,
    required this.endDate,
  });

  final String id;
  final String coupleId;
  final String title;
  final DateTime startDate;
  final DateTime endDate;

  factory Trip.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Trip(
      id: data['tripId'] as String? ?? doc.id,
      coupleId: data['coupleId'] as String,
      title: data['title'] as String? ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tripId': id,
      'coupleId': coupleId,
      'title': title,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class Plan {
  Plan({
    required this.id,
    required this.tripId,
    required this.date,
    this.time,
    required this.placeName,
    this.lat,
    this.lng,
    this.memo,
  });

  final String id;
  final String tripId;
  final DateTime date;
  final DateTime? time;
  final String placeName;
  final double? lat;
  final double? lng;
  final String? memo;

  factory Plan.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Plan(
      id: data['planId'] as String? ?? doc.id,
      tripId: data['tripId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      time: (data['time'] as Timestamp?)?.toDate(),
      placeName: data['placeName'] as String? ?? '',
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      memo: data['memo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planId': id,
      'tripId': tripId,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'time': time == null ? null : Timestamp.fromDate(time!),
      'placeName': placeName,
      'lat': lat,
      'lng': lng,
      'memo': memo,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

