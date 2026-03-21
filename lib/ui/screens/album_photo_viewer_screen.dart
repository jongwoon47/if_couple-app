import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_user.dart';
import '../../models/album_models.dart';
import '../../services/album_service.dart';

class AlbumPhotoViewerScreen extends StatelessWidget {
  const AlbumPhotoViewerScreen({
    super.key,
    required this.appUser,
    required this.album,
    required this.photo,
  });

  final AppUser appUser;
  final Album album;
  final AlbumPhoto photo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final coupleId = appUser.coupleId;
    if (coupleId == null || coupleId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.albumNoCouple)),
      );
    }

    final isCover = album.coverPhotoId == photo.photoId;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.photoViewerTitleBar),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.network(
                photo.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isCover)
                    ElevatedButton.icon(
                      onPressed: () async {
                        await AlbumService.setCoverPhoto(
                          coupleId: coupleId,
                          albumId: album.albumId,
                          coverPhotoId: photo.photoId,
                          coverPhotoUrl: photo.imageUrl,
                        );
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.star_rounded),
                      label: Text(l10n.setCoverImage),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE98ABF),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n.deletePhotoTitle),
                          content: Text(l10n.deletePhotoConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                l10n.delete,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (ok != true) return;
                      await AlbumService.deletePhoto(
                        coupleId: coupleId,
                        albumId: album.albumId,
                        photoId: photo.photoId,
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(l10n.delete),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB55C80),
                      side: const BorderSide(color: Color(0xFFB55C80)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

