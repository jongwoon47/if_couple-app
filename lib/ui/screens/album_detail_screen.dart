import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_user.dart';
import '../../models/album_models.dart';
import '../../services/album_service.dart';
import 'album_edit_screen.dart';
import 'album_photo_viewer_screen.dart';

class AlbumDetailScreen extends StatelessWidget {
  const AlbumDetailScreen({
    super.key,
    required this.appUser,
    required this.albumId,
  });

  final AppUser appUser;
  final String albumId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final coupleId = appUser.coupleId;
    if (coupleId == null || coupleId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.albumNoCouple)),
      );
    }

    final albumDocRef = FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .collection('albums')
        .doc(albumId);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.albumDetailTitleBar),
        centerTitle: true,
        actions: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: albumDocRef.snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final data = snap.data?.data();
              final album = snap.data != null && data != null
                  ? Album.fromDoc(snap.data!)
                  : null;

              if (album == null) return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AlbumEditScreen(
                        appUser: appUser,
                        existingAlbum: album,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: albumDocRef.snapshots(),
        builder: (context, albumSnap) {
          if (!albumSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final album = Album.fromDoc(albumSnap.data!);
          return Column(
            children: [
              if (album.coverPhotoUrl != null)
                Container(
                  width: double.infinity,
                  height: 220,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE6D8EA)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.network(
                      album.coverPhotoUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          size: 52,
                          color: Color(0xFFA08AA9),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 220,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8EEF9),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE6D8EA)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.photo_size_select_actual_rounded,
                      size: 52,
                      color: Color(0xFFA08AA9),
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title.isNotEmpty ? album.title : l10n.albumUntitled,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (album.memo.trim().isNotEmpty)
                      Text(
                        album.memo,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.4,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.albumTotalPhotos(album.photoCount),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8F7398),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<List<AlbumPhoto>>(
                  stream: AlbumService.photoStream(
                    coupleId: coupleId,
                    albumId: album.albumId,
                  ),
                  builder: (context, photoSnap) {
                    final photos = photoSnap.data ?? const <AlbumPhoto>[];

                    if (photoSnap.connectionState == ConnectionState.waiting &&
                        photos.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (photos.isEmpty) {
                      return Center(
                        child: Text(
                          l10n.albumNoPhotosHint,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        final photo = photos[index];
                        final isCover = album.coverPhotoId == photo.photoId;

                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AlbumPhotoViewerScreen(
                                  appUser: appUser,
                                  album: album,
                                  photo: photo,
                                ),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  photo.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (_, __, ___) =>
                                      const ColoredBox(
                                    color: Color(0xFFF0E7F0),
                                    child: Icon(Icons.broken_image_rounded),
                                  ),
                                ),
                              ),
                              if (isCover)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xE6FFFFFF),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: const Color(0xFFE6D8EA),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.coverLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFCC2E7B),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

