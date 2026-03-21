import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../l10n/app_locale_scope.dart';
import '../models/album_models.dart';
import 'app_firebase_storage.dart';

class AlbumService {
  static const int maxPhotosPerAlbumFree = 50;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static FirebaseStorage get _storage => getAppFirebaseStorage();

  static CollectionReference<Map<String, dynamic>> _albumRef(
    String coupleId,
  ) {
    return _firestore.collection('couples').doc(coupleId).collection('albums');
  }

  static CollectionReference<Map<String, dynamic>> _photoRef(
    String coupleId,
    String albumId,
  ) {
    return _albumRef(coupleId).doc(albumId).collection('photos');
  }

  static Stream<List<Album>> albumStream(String coupleId) {
    return _albumRef(coupleId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Album.fromDoc).toList());
  }

  static Stream<List<AlbumPhoto>> photoStream({
    required String coupleId,
    required String albumId,
  }) {
    return _photoRef(coupleId, albumId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AlbumPhoto.fromDoc).toList());
  }

  static Future<int> photoCount({
    required String coupleId,
    required String albumId,
  }) async {
    final snap = await _photoRef(coupleId, albumId).get();
    return snap.docs.length;
  }

  static Future<String?> photoUrl({
    required String coupleId,
    required String albumId,
    required String photoId,
  }) async {
    final doc = await _photoRef(coupleId, albumId).doc(photoId).get();
    final data = doc.data();
    if (data == null) return null;
    return data['imageUrl'] as String?;
  }

  static Future<Album> createAlbum({
    required String coupleId,
    required String title,
    required String memo,
    required String? coverPhotoId,
    required String? coverPhotoUrl,
  }) async {
    final now = DateTime.now();
    final ref = _albumRef(coupleId).doc();
    final album = Album(
      albumId: ref.id,
      coupleId: coupleId,
      title: title.trim(),
      memo: memo.trim(),
      coverPhotoId: coverPhotoId,
      coverPhotoUrl: coverPhotoUrl,
      photoCount: 0,
      createdAt: now,
      updatedAt: now,
    );

    await ref.set(album.toJson());
    return album;
  }

  static Future<void> updateAlbum({
    required String coupleId,
    required Album album,
  }) async {
    await _albumRef(coupleId).doc(album.albumId).update({
      ...album.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setCoverPhoto({
    required String coupleId,
    required String albumId,
    required String coverPhotoId,
    required String coverPhotoUrl,
  }) async {
    await _albumRef(coupleId).doc(albumId).update({
      'coverPhotoId': coverPhotoId,
      'coverPhotoUrl': coverPhotoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<String> uploadPhotos({
    required String coupleId,
    required String albumId,
    required List<List<int>> bytesList,
    required List<String> fileNames,
  }) async {
    // @return 첫 업로드된 photoId (대표 설정용)
    if (bytesList.isEmpty) return '';

    String? firstPhotoId;
    for (var i = 0; i < bytesList.length; i++) {
      final bytes = bytesList[i];
      final fileName = fileNames[i];
      final ext = _extractExtension(fileName);

      final photoId = _photoRef(coupleId, albumId).doc().id;
      final storagePath =
          'couples/$coupleId/albums/$albumId/photos/$photoId.$ext';
      final ref = _storage.ref().child(storagePath);

      final contentType = _contentTypeForExt(ext);
      final data = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      await _uploadPutData(
        ref,
        data,
        SettableMetadata(contentType: contentType),
      );
      final url = await ref.getDownloadURL().timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw TimeoutException(
          AppLocaleController.l10n.albumDownloadUrlTimeout,
        ),
      );

      await _photoRef(coupleId, albumId).doc(photoId).set({
        'photoId': photoId,
        'albumId': albumId,
        'storagePath': storagePath,
        'imageUrl': url,
        'createdAt': FieldValue.serverTimestamp(),
      });

      firstPhotoId ??= photoId;
    }

    // 업로드 후 photoCount 갱신
    final count = await photoCount(coupleId: coupleId, albumId: albumId);
    await _albumRef(coupleId).doc(albumId).update({
      'photoCount': count,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 대표(썸네일) 규칙:
    // - 앨범에 대표가 아직 없으면 → 이번 업로드 배치의 첫 장을 자동 대표로 설정
    // - 이미 대표가 있으면 → 건드리지 않음 (전체화면에서만 수동 변경)
    final fid = firstPhotoId;
    if (fid != null && fid.isNotEmpty) {
      final albumSnap = await _albumRef(coupleId).doc(albumId).get();
      final a = albumSnap.data();
      final cid = (a?['coverPhotoId'] as String?)?.trim();
      final curl = (a?['coverPhotoUrl'] as String?)?.trim();
      final hasCover =
          cid != null && cid.isNotEmpty && curl != null && curl.isNotEmpty;
      if (!hasCover) {
        final url = await photoUrl(
          coupleId: coupleId,
          albumId: albumId,
          photoId: fid,
        );
        if (url != null && url.isNotEmpty) {
          await setCoverPhoto(
            coupleId: coupleId,
            albumId: albumId,
            coverPhotoId: fid,
            coverPhotoUrl: url,
          );
        }
      }
    }

    return firstPhotoId ?? '';
  }

  static Future<void> deletePhoto({
    required String coupleId,
    required String albumId,
    required String photoId,
  }) async {
    final photoDoc = await _photoRef(coupleId, albumId).doc(photoId).get();
    if (!photoDoc.exists) return;
    final data = photoDoc.data()!;
    final storagePath = data['storagePath'] as String?;

    // Storage 먼저 삭제 시도 (실패해도 Firestore는 계속 진행)
    if (storagePath != null && storagePath.isNotEmpty) {
      try {
        await _storage.ref().child(storagePath).delete();
      } catch (_) {}
    }

    await _photoRef(coupleId, albumId).doc(photoId).delete();

    // cover가 삭제된 경우: 남은 사진 중 최신 1장을 대표로
    final albumDoc = await _albumRef(coupleId).doc(albumId).get();
    final coverPhotoId = albumDoc.data()?['coverPhotoId'] as String?;
    if (coverPhotoId == photoId) {
      final remaining = await _photoRef(coupleId, albumId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (remaining.docs.isEmpty) {
        await _albumRef(coupleId).doc(albumId).update({
          'coverPhotoId': null,
          'coverPhotoUrl': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final remainingDoc = remaining.docs.first;
        final remainingData = remainingDoc.data();
        await _albumRef(coupleId).doc(albumId).update({
          'coverPhotoId': remainingData['photoId'] ?? remainingDoc.id,
          'coverPhotoUrl': remainingData['imageUrl'],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    final count = await photoCount(coupleId: coupleId, albumId: albumId);
    await _albumRef(coupleId).doc(albumId).update({
      'photoCount': count,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteAlbum({
    required String coupleId,
    required String albumId,
  }) async {
    final photos = await _photoRef(coupleId, albumId).get();
    final batch = _firestore.batch();

    for (final doc in photos.docs) {
      batch.delete(doc.reference);

      // Storage도 삭제 시도
      final storagePath = (doc.data())['storagePath'] as String?;
      if (storagePath != null && storagePath.isNotEmpty) {
        unawaited(_storage.ref().child(storagePath).delete().catchError((_) {}));
      }
    }

    batch.delete(_albumRef(coupleId).doc(albumId));
    await batch.commit();
  }

  static String _extractExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) return 'jpg';
    final ext = parts.last.toLowerCase();
    if (ext == 'png' || ext == 'jpg' || ext == 'jpeg' || ext == 'webp' || ext == 'gif') {
      return ext == 'jpeg' ? 'jpg' : ext;
    }
    return 'jpg';
  }

  /// 웹에서 업로드가 무한 대기할 때(네트워크·CORS 등) UI가 멈추지 않도록 제한
  static Future<void> _uploadPutData(
    Reference ref,
    Uint8List data,
    SettableMetadata metadata,
  ) async {
    final task = ref.putData(data, metadata);
    try {
      await task.timeout(
        const Duration(minutes: 3),
        onTimeout: () => throw TimeoutException(
          AppLocaleController.l10n.albumUploadTimeoutBody,
        ),
      );
    } on TimeoutException catch (_) {
      await task.cancel();
      rethrow;
    }
  }

  static String _contentTypeForExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }
}

