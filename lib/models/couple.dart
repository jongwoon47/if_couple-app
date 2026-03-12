import 'package:cloud_firestore/cloud_firestore.dart';

class Couple {
  const Couple({
    required this.coupleId,
    required this.user1Id,
    required this.user2Id,
    required this.startDate,
    this.createdAt,
  });

  final String coupleId;
  final String user1Id;
  final String user2Id;
  final DateTime startDate;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'coupleId': coupleId,
      'user1Id': user1Id,
      'user2Id': user2Id,
      'startDate': Timestamp.fromDate(startDate),
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
    };
  }

  factory Couple.fromMap(Map<String, dynamic> map) {
    final coupleId =
        ((map['coupleId'] ?? map['id']) ?? '').toString();
    final usersList = map['users'] as List<dynamic>?;
    final user1Id = (map['user1Id'] ?? '') as String;
    final user2Id = (map['user2Id'] ?? '') as String;
    final fromUsers = usersList != null && usersList.length >= 2
        ? usersList.map((e) => e.toString()).toList()
        : <String>[];
    return Couple(
      coupleId: coupleId,
      user1Id: user1Id.isNotEmpty ? user1Id : (fromUsers.isNotEmpty ? fromUsers[0] : ''),
      user2Id: user2Id.isNotEmpty ? user2Id : (fromUsers.length >= 2 ? fromUsers[1] : ''),
      startDate: ((map['startDate'] as Timestamp?) ?? Timestamp.now()).toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
