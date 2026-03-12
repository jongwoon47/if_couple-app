import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class UserService {
  static final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');

  static Future<void> createUserIfNotExists(User firebaseUser) async {
    final docRef = _users.doc(firebaseUser.uid);
    final doc = await docRef.get();
    if (doc.exists) return;

    await docRef.set({
      'userId': firebaseUser.uid,
      'email': firebaseUser.email ?? '',
      'nickname': '',
      'partnerNickname': '',
      'statusMessage': '',
      'birthday': null,
      'gender': null,
      'language': '',
      'startDate': null,
      'coupleId': null,
      'activeInviteCode': null,
      'coupleJoinedAt': null,
      'hasSeenConnectionComplete': true,
      'notificationAllEnabled': true,
      'notificationMessageEnabled': true,
      'notificationAlbumEnabled': true,
      'notificationAnniversaryEnabled': true,
      'notificationScheduleEnabled': true,
      'notificationTime': '09:00',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<AppUser?> getUser(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!);
  }

  static Stream<AppUser?> userStream(String userId) {
    return _users.doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(doc.data()!);
    });
  }

  static Future<void> updateProfile({
    required String userId,
    required String nickname,
    required DateTime birthday,
    required String language,
    String? gender,
  }) async {
    await _users.doc(userId).set({
      'nickname': nickname.trim(),
      'birthday': Timestamp.fromDate(birthday),
      'language': language.trim(),
      'gender': gender,
    }, SetOptions(merge: true));
  }

  static Future<void> updateSettingsProfile({
    required String userId,
    required String nickname,
    required DateTime startDate,
  }) async {
    await _users.doc(userId).set({
      'nickname': nickname.trim(),
      'startDate': Timestamp.fromDate(startDate),
    }, SetOptions(merge: true));
  }

  /// 커플인데 파트너 닉네임이 비어 있으면 상대 문서에서 가져와 동기화 (기존 연결된 커플용)
  static Future<void> syncPartnerNicknameIfNeeded({
    required String userId,
    required String coupleId,
    required String currentPartnerNickname,
  }) async {
    if (currentPartnerNickname.trim().isNotEmpty) return;
    final coupleDoc = await FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .get();
    if (!coupleDoc.exists || coupleDoc.data() == null) return;
    final data = coupleDoc.data()!;
    final user1Id = (data['user1Id'] ?? '') as String;
    final user2Id = (data['user2Id'] ?? '') as String;
    final partnerId = user1Id == userId ? user2Id : user1Id;
    if (partnerId.isEmpty) return;
    final partnerDoc = await _users.doc(partnerId).get();
    if (!partnerDoc.exists || partnerDoc.data() == null) return;
    final partnerNickname = ((partnerDoc.data()!['nickname'] ?? '') as String).trim();
    if (partnerNickname.isEmpty) return;
    await _users.doc(userId).set({
      'partnerNickname': partnerNickname,
    }, SetOptions(merge: true));
  }

  static Future<void> updateNotificationSettings({
    required String userId,
    required bool allEnabled,
    required bool messageEnabled,
    required bool albumEnabled,
    required bool anniversaryEnabled,
    required bool scheduleEnabled,
    required String notificationTime,
  }) async {
    await _users.doc(userId).set({
      'notificationAllEnabled': allEnabled,
      'notificationMessageEnabled': messageEnabled,
      'notificationAlbumEnabled': albumEnabled,
      'notificationAnniversaryEnabled': anniversaryEnabled,
      'notificationScheduleEnabled': scheduleEnabled,
      'notificationTime': notificationTime.trim(),
    }, SetOptions(merge: true));
  }

  static Future<void> markConnectionCompleteSeen(String userId) async {
    await _users.doc(userId).set({
      'hasSeenConnectionComplete': true,
    }, SetOptions(merge: true));
  }
}
