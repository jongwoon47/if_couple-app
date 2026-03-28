import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

import '../models/couple.dart';
import 'album_service.dart';
import 'app_firebase_storage.dart';
import 'trip_service.dart';

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

    throw Exception('INVITE_CREATE_FAILED');
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
          return '${_txErrorPrefix}INVALID_CODE';
        }

        final invite = InviteCodeInfo.fromDoc(inviteSnap);

        if (invite.used) {
          return '${_txErrorPrefix}INVALID_CODE';
        }

        if (!invite.expiresAt.isAfter(now)) {
          return '${_txErrorPrefix}INVITE_EXPIRED';
        }

        if (invite.createdBy == currentUserUid) {
          return '${_txErrorPrefix}INVALID_CODE';
        }

        final userARef = _users.doc(invite.createdBy);
        final userBRef = _users.doc(currentUserUid);

        final userASnap = await tx.get(userARef);
        final userBSnap = await tx.get(userBRef);

        if (!userASnap.exists || !userBSnap.exists) {
          return '${_txErrorPrefix}INVALID_CODE';
        }

        final userAData = userASnap.data()!;
        final userBData = userBSnap.data()!;

        final userACoupleId = (userAData['coupleId'] ?? '') as String;
        final userBCoupleId = (userBData['coupleId'] ?? '') as String;

        if (userACoupleId.isNotEmpty || userBCoupleId.isNotEmpty) {
          return '${_txErrorPrefix}INVALID_CODE';
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
          'lastCoupleId': FieldValue.delete(),
          'coupleDisconnectedAt': FieldValue.delete(),
        });
        tx.update(userBRef, {
          'coupleId': coupleRef.id,
          'hasSeenConnectionComplete': false,
          'coupleJoinedAt': Timestamp.fromDate(now),
          'partnerNickname': nicknameA.trim().isEmpty ? '' : nicknameA,
          'lastCoupleId': FieldValue.delete(),
          'coupleDisconnectedAt': FieldValue.delete(),
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

  /// 연결만 끊고 커플 데이터(채팅·앨범 등)는 서버에 남깁니다. (탈퇴 시에만 전체 삭제)
  static Future<void> disconnectCouple({
    required String currentUserUid,
  }) async {
    final currentUserRef = _users.doc(currentUserUid);

    final userUnlinkUpdate = <String, dynamic>{
      'coupleId': null,
      'hasSeenConnectionComplete': true,
      'coupleJoinedAt': null,
      'partnerNickname': '',
      'startDate': FieldValue.delete(),
    };

    try {
      final currentUserSnap = await currentUserRef.get();
      if (!currentUserSnap.exists || currentUserSnap.data() == null) {
        throw Exception('USER_NOT_FOUND');
      }

      final currentUserData = currentUserSnap.data()!;
      final coupleId = (currentUserData['coupleId'] ?? '') as String;
      if (coupleId.isEmpty) {
        return;
      }

      final coupleRef = _couples.doc(coupleId);
      final coupleSnap = await coupleRef.get();

      if (!coupleSnap.exists || coupleSnap.data() == null) {
        await currentUserRef.update({
          ...userUnlinkUpdate,
          'lastCoupleId': coupleId,
          'coupleDisconnectedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      final usersRaw = (coupleSnap.data()!['users'] as List?) ?? const [];
      final users = usersRaw
          .map((value) => value.toString())
          .where((uid) => uid.isNotEmpty)
          .toSet()
          .toList();

      if (!users.contains(currentUserUid)) {
        throw Exception('CONNECTION_INVALID');
      }

      final batch = _firestore.batch();
      batch.update(coupleRef, {
        'disconnectedAt': FieldValue.serverTimestamp(),
        'disconnectedBy': currentUserUid,
      });
      for (final uid in users) {
        batch.update(_users.doc(uid), {
          ...userUnlinkUpdate,
          'lastCoupleId': coupleId,
          'coupleDisconnectedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      for (final uid in users) {
        await _invalidateOpenCodes(uid);
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('DISCONNECT_PERMISSION_DENIED');
      }
      throw Exception('DISCONNECT_ERROR:${e.code}');
    }
  }

  /// [reconnectGracePeriod] 이내·상대도 동일 lastCoupleId일 때만 복구.
  static const Duration reconnectGracePeriod = Duration(days: 90);

  /// 이전 연결 복구 (양쪽이 같은 lastCoupleId를 갖고, 커플 문서가 해제 상태일 때)
  static Future<void> tryRestoreCouple(String currentUserUid) async {
    final userRef = _users.doc(currentUserUid);
    final userSnap = await userRef.get();
    if (!userSnap.exists || userSnap.data() == null) {
      throw Exception('USER_NOT_FOUND');
    }
    final data = userSnap.data()!;
    final lastCoupleId = (data['lastCoupleId'] ?? '') as String;
    final disconnectedAtRaw = data['coupleDisconnectedAt'];
    if (lastCoupleId.isEmpty || disconnectedAtRaw is! Timestamp) {
      throw Exception('RESTORE_NOT_AVAILABLE');
    }
    if (DateTime.now().difference(disconnectedAtRaw.toDate()) >
        reconnectGracePeriod) {
      throw Exception('RESTORE_EXPIRED');
    }

    final coupleRef = _couples.doc(lastCoupleId);
    final coupleSnap = await coupleRef.get();
    if (!coupleSnap.exists || coupleSnap.data() == null) {
      throw Exception('COUPLE_NOT_FOUND');
    }
    final cData = coupleSnap.data()!;
    final dAt = cData['disconnectedAt'];
    if (dAt is! Timestamp) {
      throw Exception('COUPLE_NOT_DISCONNECTED');
    }
    if (DateTime.now().difference(dAt.toDate()) > reconnectGracePeriod) {
      throw Exception('RESTORE_EXPIRED');
    }

    final usersRaw = (cData['users'] as List?) ?? const [];
    final memberUids = usersRaw
        .map((e) => e.toString())
        .where((id) => id.isNotEmpty)
        .toList();
    if (!memberUids.contains(currentUserUid) || memberUids.length != 2) {
      throw Exception('NOT_MEMBER');
    }
    final partnerUid = memberUids.firstWhere((u) => u != currentUserUid);

    final partnerSnap = await _users.doc(partnerUid).get();
    if (!partnerSnap.exists || partnerSnap.data() == null) {
      throw Exception('PARTNER_NOT_FOUND');
    }
    final pd = partnerSnap.data()!;
    final partnerLast = (pd['lastCoupleId'] ?? '') as String;
    final partnerDisconnected = pd['coupleDisconnectedAt'];
    if (partnerLast != lastCoupleId || partnerDisconnected is! Timestamp) {
      throw Exception('PARTNER_NOT_READY');
    }
    if (DateTime.now().difference(partnerDisconnected.toDate()) >
        reconnectGracePeriod) {
      throw Exception('RESTORE_EXPIRED');
    }

    final myNickname = (data['nickname'] ?? '') as String;
    final partnerNickname = (pd['nickname'] ?? '') as String;
    final coupleStart = cData['startDate'] as Timestamp?;

    await _firestore.runTransaction<void>((tx) async {
      tx.update(coupleRef, {
        'disconnectedAt': FieldValue.delete(),
        'disconnectedBy': FieldValue.delete(),
      });
      final userUpdate = <String, dynamic>{
        'coupleId': lastCoupleId,
        'lastCoupleId': FieldValue.delete(),
        'coupleDisconnectedAt': FieldValue.delete(),
        'partnerNickname':
            partnerNickname.trim().isEmpty ? '' : partnerNickname.trim(),
        'hasSeenConnectionComplete': true,
        'coupleJoinedAt': FieldValue.serverTimestamp(),
      };
      final partnerUpdate = <String, dynamic>{
        'coupleId': lastCoupleId,
        'lastCoupleId': FieldValue.delete(),
        'coupleDisconnectedAt': FieldValue.delete(),
        'partnerNickname': myNickname.trim().isEmpty ? '' : myNickname.trim(),
        'hasSeenConnectionComplete': true,
        'coupleJoinedAt': FieldValue.serverTimestamp(),
      };
      if (coupleStart != null) {
        userUpdate['startDate'] = coupleStart;
        partnerUpdate['startDate'] = coupleStart;
      }
      tx.update(userRef, userUpdate);
      tx.update(_users.doc(partnerUid), partnerUpdate);
    });
  }

  /// 회원 탈퇴: 내 users 문서 삭제·커플에 탈퇴 표시. **두 명 모두** 탈퇴하면 커플 데이터 전체 삭제.
  static Future<void> onUserAccountDeletion(String uid) async {
    final userRef = _users.doc(uid);
    final userSnap = await userRef.get();
    if (!userSnap.exists || userSnap.data() == null) return;

    final data = userSnap.data()!;
    final activeCoupleId = (data['coupleId'] ?? '') as String;
    final lastCoupleId = (data['lastCoupleId'] ?? '') as String;
    final targetCoupleId =
        activeCoupleId.isNotEmpty ? activeCoupleId : lastCoupleId;

    if (targetCoupleId.isEmpty) {
      await userRef.delete();
      return;
    }

    final coupleRef = _couples.doc(targetCoupleId);
    final coupleSnap = await coupleRef.get();

    final batch = _firestore.batch();

    if (coupleSnap.exists) {
      final cData = coupleSnap.data()!;
      final usersRaw = (cData['users'] as List?) ?? const [];
      final memberUids = usersRaw
          .map((e) => e.toString())
          .where((id) => id.isNotEmpty)
          .toList();

      batch.update(coupleRef, {
        'accountDeletedUids': FieldValue.arrayUnion([uid]),
        if (cData['disconnectedAt'] == null) ...<String, dynamic>{
          'disconnectedAt': FieldValue.serverTimestamp(),
          'disconnectedBy': uid,
        },
      });

      final unlinkOther = <String, dynamic>{
        'coupleId': null,
        'partnerNickname': '',
        'startDate': FieldValue.delete(),
        'lastCoupleId': targetCoupleId,
        'coupleDisconnectedAt': FieldValue.serverTimestamp(),
        'hasSeenConnectionComplete': true,
        'coupleJoinedAt': null,
      };

      for (final otherUid in memberUids) {
        if (otherUid == uid) continue;
        batch.update(_users.doc(otherUid), unlinkOther);
      }
    }

    batch.delete(userRef);
    await batch.commit();

    final afterSnap = await coupleRef.get();
    if (!afterSnap.exists) return;
    final cd = afterSnap.data()!;
    final usersList = (cd['users'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
    final deletedList = (cd['accountDeletedUids'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    if (usersList.length >= 2 &&
        usersList.every((u) => deletedList.contains(u))) {
      await _purgeCoupleData(targetCoupleId);
    }
  }

  /// couples/{coupleId} 하위 문서·Storage 전부 삭제 후 커플 루트 문서 삭제.
  static Future<void> _purgeCoupleData(String coupleId) async {
    final coupleRef = _couples.doc(coupleId);

    await _deleteCollectionInBatches(coupleRef.collection('messages'));
    await _deleteCollectionInBatches(coupleRef.collection('events'));

    final tripsSnap = await coupleRef.collection('trips').get();
    for (final doc in tripsSnap.docs) {
      await TripService.deleteTrip(coupleId: coupleId, tripId: doc.id);
    }

    final albumsSnap = await coupleRef.collection('albums').get();
    for (final doc in albumsSnap.docs) {
      await AlbumService.deleteAlbum(coupleId: coupleId, albumId: doc.id);
    }

    await coupleRef.delete();

    try {
      await _deleteStoragePrefix('couples/$coupleId');
    } catch (_) {
      // Firestore는 이미 비움. Storage만 남는 경우는 무시(규칙·네트워크)
    }
  }

  static Future<void> _deleteCollectionInBatches(
    CollectionReference<Map<String, dynamic>> ref,
  ) async {
    while (true) {
      final snap = await ref.limit(500).get();
      if (snap.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  static Future<void> _deleteStoragePrefix(String path) async {
    final storage = getAppFirebaseStorage();
    final ref = storage.ref(path);
    await _deleteStorageRefRecursive(ref);
  }

  static Future<void> _deleteStorageRefRecursive(Reference ref) async {
    final list = await ref.listAll();
    for (final prefix in list.prefixes) {
      await _deleteStorageRefRecursive(prefix);
    }
    for (final item in list.items) {
      try {
        await item.delete();
      } catch (_) {}
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
