import 'package:cloud_firestore/cloud_firestore.dart';

class Album {
  const Album({
    required this.albumId,
    required this.coupleId,
    required this.title,
    required this.memo,
    required this.coverPhotoId,
    required this.coverPhotoUrl,
    required this.photoCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String albumId;
  final String coupleId;
  final String title;
  final String memo;

  /// 대표 사진 (없을 수도 있음: coverPhotoId / coverPhotoUrl 둘 다 null)
  final String? coverPhotoId;
  final String? coverPhotoUrl;

  final int photoCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Album.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final createdAt = (d['createdAt'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final updatedAt = (d['updatedAt'] as Timestamp?)?.toDate() ?? createdAt;
    return Album(
      albumId: (d['albumId'] as String?) ?? doc.id,
      coupleId: d['coupleId'] as String,
      title: (d['title'] as String?) ?? '',
      memo: (d['memo'] as String?) ?? '',
      coverPhotoId: d['coverPhotoId'] as String?,
      coverPhotoUrl: d['coverPhotoUrl'] as String?,
      photoCount: (d['photoCount'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'albumId': albumId,
      'coupleId': coupleId,
      'title': title,
      'memo': memo,
      'coverPhotoId': coverPhotoId,
      'coverPhotoUrl': coverPhotoUrl,
      'photoCount': photoCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class AlbumPhoto {
  const AlbumPhoto({
    required this.photoId,
    required this.albumId,
    required this.storagePath,
    required this.imageUrl,
    required this.createdAt,
  });

  final String photoId;
  final String albumId;
  final String storagePath;
  final String imageUrl;
  final DateTime createdAt;

  factory AlbumPhoto.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AlbumPhoto(
      photoId: (d['photoId'] as String?) ?? doc.id,
      albumId: d['albumId'] as String,
      storagePath: d['storagePath'] as String,
      imageUrl: d['imageUrl'] as String,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }
}

