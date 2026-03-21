import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_user.dart';
import '../../models/album_models.dart';
import '../../services/album_service.dart';
import 'album_detail_screen.dart';
import 'album_edit_screen.dart';

class AlbumListScreen extends StatelessWidget {
  const AlbumListScreen({super.key, required this.appUser});

  final AppUser appUser;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final coupleId = appUser.coupleId;
    if (coupleId == null || coupleId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.albumNoCouple)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.albumTitle),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Album>>(
        stream: AlbumService.albumStream(coupleId),
        builder: (context, snapshot) {
          final albums = snapshot.data ?? const <Album>[];

          if (snapshot.connectionState == ConnectionState.waiting &&
              albums.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (albums.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library_rounded,
                      size: 54,
                      color: Color(0xFFD167A0),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.albumEmptyTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF755379),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.albumEmptySubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8F7398),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            itemCount: albums.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final album = albums[index];
              final coverUrl = album.coverPhotoUrl;
              final dateText =
                  DateFormat('yyyy.MM.dd').format(album.createdAt);

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AlbumDetailScreen(
                        appUser: appUser,
                        albumId: album.albumId,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x08000000),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8EEF9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE6D8EA)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: coverUrl == null
                            ? const Icon(
                                Icons.image_outlined,
                                color: Color(0xFFA08AA9),
                              )
                            : Image.network(
                                coverUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image_outlined),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              album.title.isNotEmpty ? album.title : l10n.albumUntitled,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$dateText · ${l10n.albumPhotoCountShort(album.photoCount)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AlbumEditScreen(appUser: appUser),
            ),
          );
        },
        backgroundColor: const Color(0xFFE98ABF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.albumAdd),
      ),
    );
  }
}
