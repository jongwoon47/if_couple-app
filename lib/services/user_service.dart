import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class UserService {
  static final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');

  /// 세션당 uid 1회: 레거시 필드 제거·불일치 플래그 보정 (배포 전 기존 DB 정리용)
  static String? _sessionRepairedUserId;
  static String? _repairScheduledForUserId;

  /// [AppGate]에서 매 빌드 호출 → true일 때만 `addPostFrameCallback`으로 [repairUserDocumentIfNeeded] 실행
  static bool shouldScheduleUserDocumentRepair(AppUser user) {
    if (_repairScheduledForUserId == user.userId) return false;
    _repairScheduledForUserId = user.userId;
    return true;
  }

  /// 기존 사용자 문서 정리:
  /// - 커플 미연결인데 `hasSeenConnectionComplete == true` → false (초대 코드 화면 건너뛰기 방지)
  /// - 사용하지 않는 `activeInviteCode` 필드 삭제 (초대는 `inviteCodes` 컬렉션만 사용)
  static Future<void> repairUserDocumentIfNeeded(AppUser user) async {
    if (_sessionRepairedUserId == user.userId) return;
    _sessionRepairedUserId = user.userId;

    final updates = <String, dynamic>{};

    if ((user.coupleId == null || user.coupleId!.isEmpty) &&
        user.hasSeenConnectionComplete) {
      updates['hasSeenConnectionComplete'] = false;
    }

    final snap = await _users.doc(user.userId).get();
    final data = snap.data();
    if (data != null && data.containsKey('activeInviteCode')) {
      updates['activeInviteCode'] = FieldValue.delete();
    }

    if (updates.isEmpty) return;
    await _users.doc(user.userId).set(updates, SetOptions(merge: true));
  }

  static Future<void> saveConsent({
    required String userId,
    required bool agreePrivacyPolicy,
    required bool agreeTermsOfService,
    required bool agreeAgeConfirm,
    required bool agreeMarketing,
    required String privacyPolicyVersion,
    required String termsOfServiceVersion,
  }) async {
    final now = Timestamp.fromDate(DateTime.now());
    await _users.doc(userId).set({
      if (agreePrivacyPolicy) 'privacyPolicyAcceptedAt': now,
      if (agreeTermsOfService) 'termsOfServiceAcceptedAt': now,
      if (agreeAgeConfirm) 'ageConfirmedAt': now,
      'privacyPolicyVersion': privacyPolicyVersion,
      'termsOfServiceVersion': termsOfServiceVersion,
      'marketingConsentAcceptedAt': agreeMarketing ? now : null,
    }, SetOptions(merge: true));
  }

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
      'coupleJoinedAt': null,
      // 커플 연결 축하 화면을 보려면 false에서 시작 (연결 후 true로 갱신)
      'hasSeenConnectionComplete': false,
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

  static Future<void> addFcmToken({
    required String userId,
    required String token,
  }) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return;
    await _users.doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([trimmed]),
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
