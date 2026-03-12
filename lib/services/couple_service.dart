import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/couple.dart';

class InviteCodeInfo {
  const InviteCodeInfo({
    required this.code,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    required this.used,
  });

  final String code;
  final String createdBy;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool used;

  Duration get remaining => expiresAt.difference(DateTime.now());

  bool get isExpired => !expiresAt.isAfter(DateTime.now());

  factory InviteCodeInfo.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return InviteCodeInfo(
      code: (data['code'] ?? doc.id) as String,
      createdBy: (data['createdBy'] ?? '') as String,
      createdAt: ((data['createdAt'] as Timestamp?) ?? Timestamp.now()).toDate(),
      expiresAt: ((data['expiresAt'] as Timestamp?) ?? Timestamp.now()).toDate(),
      used: (data['used'] ?? false) as bool,
    );
  }
}

class CoupleService {
  CoupleService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  static CollectionReference<Map<String, dynamic>> get _couples =>
      _firestore.collection('couples');
  static CollectionReference<Map<String, dynamic>> get _inviteCodes =>
      _firestore.collection('inviteCodes');

  static const Duration inviteValidity = Duration(minutes: 10);
  static const String _txErrorPrefix = '__TX_ERROR__:';

  static String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  static Future<void> _invalidateOpenCodes(String uid) async {
    final query = await _inviteCodes
        .where('createdBy', isEqualTo: uid)
        .where('used', isEqualTo: false)
        .get();

    if (query.docs.isEmpty) return;

    final now = Timestamp.now();
    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {
        'used': true,
        'invalidatedAt': now,
      });
    }
    await batch.commit();
  }

  static Future<InviteCodeInfo?> getLatestActiveInviteCode(String uid) async {
    final query = await _inviteCodes
        .where('createdBy', isEqualTo: uid)
        .where('used', isEqualTo: false)
        .limit(10)
        .get();

    final docs = [...query.docs];
    docs.sort((a, b) {
      final aTs = (a.data()['createdAt'] as Timestamp?) ?? Timestamp(0, 0);
      final bTs = (b.data()['createdAt'] as Timestamp?) ?? Timestamp(0, 0);
      return bTs.compareTo(aTs);
    });

    for (final doc in docs) {
      final invite = InviteCodeInfo.fromDoc(doc);
      if (!invite.isExpired) {
        return invite;
      }
    }
    return null;
  }

  static Future<InviteCodeInfo> createInviteCode(String createdByUid) async {
    await _invalidateOpenCodes(createdByUid);

    for (var i = 0; i < 30; i++) {
      final code = _generateRandomCode();
      final ref = _inviteCodes.doc(code);
      final exists = await ref.get();
      if (exists.exists) continue;

      final now = DateTime.now();
      final expiresAt = now.add(inviteValidity);

      await ref.set({
        'code': code,
        'createdBy': createdByUid,
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'used': false,
      });

      return InviteCodeInfo(
        code: code,
        createdBy: createdByUid,
        createdAt: now,
        expiresAt: expiresAt,
        used: false,
      );
    }

    throw Exception('초대 코드 생성에 실패했습니다.');
  }

  static Future<String> connectWithInviteCode({
    required String currentUserUid,
    required String inviteCode,
  }) async {
    final normalizedCode = inviteCode.trim().toUpperCase();
    final inviteRef = _inviteCodes.doc(normalizedCode);

    try {
      final result = await _firestore.runTransaction<String>((
        tx,
      ) async {
        final now = DateTime.now();
        final inviteSnap = await tx.get(inviteRef);

        if (!inviteSnap.exists || inviteSnap.data() == null) {
          return '$_txErrorPrefix유효하지 않은 코드입니다.';
        }

        final invite = InviteCodeInfo.fromDoc(inviteSnap);

        if (invite.used) {
          return '$_txErrorPrefix유효하지 않은 코드입니다.';
        }

        if (!invite.expiresAt.isAfter(now)) {
          return '$_txErrorPrefix초대 코드가 만료되었습니다.';
        }

        if (invite.createdBy == currentUserUid) {
          return '$_txErrorPrefix유효하지 않은 코드입니다.';
        }

        final userARef = _users.doc(invite.createdBy);
        final userBRef = _users.doc(currentUserUid);

        final userASnap = await tx.get(userARef);
        final userBSnap = await tx.get(userBRef);

        if (!userASnap.exists || !userBSnap.exists) {
          return '$_txErrorPrefix유효하지 않은 코드입니다.';
        }

        final userAData = userASnap.data()!;
        final userBData = userBSnap.data()!;

        final userACoupleId = (userAData['coupleId'] ?? '') as String;
        final userBCoupleId = (userBData['coupleId'] ?? '') as String;

        if (userACoupleId.isNotEmpty || userBCoupleId.isNotEmpty) {
          return '$_txErrorPrefix유효하지 않은 코드입니다.';
        }

        final coupleRef = _couples.doc();
        final startDateOnly = DateTime(now.year, now.month, now.day);

        tx.set(coupleRef, {
          'id': coupleRef.id,
          'coupleId': coupleRef.id,
          'users': [invite.createdBy, currentUserUid],
          'user1Id': invite.createdBy,
          'user2Id': currentUserUid,
          'startDate': Timestamp.fromDate(startDateOnly),
          'createdAt': Timestamp.fromDate(now),
        });

        final nicknameA = (userAData['nickname'] ?? '') as String;
        final nicknameB = (userBData['nickname'] ?? '') as String;
        tx.update(userARef, {
          'coupleId': coupleRef.id,
          'hasSeenConnectionComplete': false,
          'coupleJoinedAt': Timestamp.fromDate(now),
          'partnerNickname': nicknameB.trim().isEmpty ? '' : nicknameB,
        });
        tx.update(userBRef, {
          'coupleId': coupleRef.id,
          'hasSeenConnectionComplete': false,
          'coupleJoinedAt': Timestamp.fromDate(now),
          'partnerNickname': nicknameA.trim().isEmpty ? '' : nicknameA,
        });

        tx.update(inviteRef, {
          'used': true,
          'usedAt': Timestamp.fromDate(now),
          'usedBy': currentUserUid,
        });

        return coupleRef.id;
      });

      if (result.startsWith(_txErrorPrefix)) {
        throw Exception(result.substring(_txErrorPrefix.length));
      }

      return result;
    } on FirebaseException {
      // UI에서 메시지 추출을 위해 그대로 전달 (웹에서 boxed 되지 않도록)
      rethrow;
    }
  }

  static Stream<Couple?> coupleStream(String coupleId) {
    return _couples.doc(coupleId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Couple.fromMap(doc.data()!);
    });
  }

  static Future<void> disconnectCouple({
    required String currentUserUid,
  }) async {
    final currentUserRef = _users.doc(currentUserUid);

    try {
      final result = await _firestore.runTransaction<String>((
        tx,
      ) async {
        final currentUserSnap = await tx.get(currentUserRef);
        if (!currentUserSnap.exists || currentUserSnap.data() == null) {
          return '$_txErrorPrefix사용자 정보를 찾을 수 없습니다.';
        }

        final currentUserData = currentUserSnap.data()!;
        final coupleId = (currentUserData['coupleId'] ?? '') as String;
        if (coupleId.isEmpty) {
          return '';
        }

        final coupleRef = _couples.doc(coupleId);
        final coupleSnap = await tx.get(coupleRef);

        final userUnlinkUpdate = {
          'coupleId': null,
          'hasSeenConnectionComplete': true,
          'coupleJoinedAt': null,
        };

        if (!coupleSnap.exists || coupleSnap.data() == null) {
          tx.update(currentUserRef, userUnlinkUpdate);
          return '';
        }

        final usersRaw = (coupleSnap.data()!['users'] as List?) ?? const [];
        final users = usersRaw
            .map((value) => value.toString())
            .where((uid) => uid.isNotEmpty)
            .toSet()
            .toList();

        if (!users.contains(currentUserUid)) {
          return '$_txErrorPrefix연결 정보가 올바르지 않습니다.';
        }

        for (final uid in users) {
          tx.update(_users.doc(uid), userUnlinkUpdate);
        }

        tx.update(coupleRef, {
          'disconnectedAt': Timestamp.fromDate(DateTime.now()),
          'disconnectedBy': currentUserUid,
        });

        return '';
      });

      if (result.startsWith(_txErrorPrefix)) {
        throw Exception(result.substring(_txErrorPrefix.length));
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('연결 해제 권한이 없습니다. Firestore 규칙을 확인해 주세요.');
      }
      throw Exception('연결 해제 중 오류가 발생했습니다. (${e.code})');
    }
  }

  static Future<String?> getCoupleStartDateString(String coupleId) async {
    final doc = await _couples.doc(coupleId).get();
    if (!doc.exists || doc.data() == null) return null;
    final couple = Couple.fromMap(doc.data()!);
    return DateFormat('yyyy-MM-dd').format(couple.startDate);
  }

  /// 처음만난날 저장.
  /// [forceUpdate] false(기본): 연결 후 첫 입력 시 먼저 저장한 사람 값만 적용(동시 입력이면 먼저 저장한 쪽 우선).
  /// [forceUpdate] true: 설정 등에서 수정 시 항상 덮어쓰기.
  static Future<void> updateCoupleStartDate({
    required String coupleId,
    required DateTime startDate,
    required String currentUserId,
    bool forceUpdate = false,
  }) async {
    final coupleRef = _couples.doc(coupleId);

    await _firestore.runTransaction<void>((tx) async {
      final coupleSnap = await tx.get(coupleRef);
      if (!coupleSnap.exists || coupleSnap.data() == null) {
        throw Exception('커플 정보를 찾을 수 없습니다.');
      }
      final data = coupleSnap.data()!;
      final submittedBy = (data['startDateSubmittedBy'] ?? '') as String;

      if (!forceUpdate && submittedBy.isNotEmpty) {
        // 이미 누군가(A) 먼저 입력함 → 기존 날짜로 현재 사용자만 동기화 후 홈으로
        final existingTs = data['startDate'] as Timestamp?;
        if (existingTs != null) {
          tx.update(_users.doc(currentUserId), {'startDate': existingTs});
        }
        return;
      }

      final user1Id = (data['user1Id'] ?? '') as String;
      final user2Id = (data['user2Id'] ?? '') as String;
      final ts = Timestamp.fromDate(startDate);

      tx.update(coupleRef, {
        'startDate': ts,
        'startDateSubmittedBy': currentUserId,
      });
      if (user1Id.isNotEmpty) tx.update(_users.doc(user1Id), {'startDate': ts});
      if (user2Id.isNotEmpty) tx.update(_users.doc(user2Id), {'startDate': ts});
    });
  }
}
