import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_user.dart';
import '../../models/album_models.dart';
import '../../services/album_service.dart';
import '../../utils/download_network_image.dart';

/// 앨범 사진 상세 — 좌우 스와이프로 다음/이전 사진
class AlbumPhotoViewerScreen extends StatefulWidget {
  const AlbumPhotoViewerScreen({
    super.key,
    required this.appUser,
    required this.album,
    required this.photos,
    required this.initialIndex,
  });

  final AppUser appUser;
  final Album album;
  final List<AlbumPhoto> photos;
  final int initialIndex;

  @override
  State<AlbumPhotoViewerScreen> createState() => _AlbumPhotoViewerScreenState();
}

class _AlbumPhotoViewerScreenState extends State<AlbumPhotoViewerScreen> {
  late PageController _pageController;
  late List<AlbumPhoto> _photos;
  late int _currentIndex;
  String? _coverPhotoId;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _photos = List<AlbumPhoto>.from(widget.photos);
    _coverPhotoId = widget.album.coverPhotoId;
    final max = _photos.isEmpty ? 0 : _photos.length - 1;
    _currentIndex = widget.initialIndex.clamp(0, max);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  AlbumPhoto get _currentPhoto => _photos[_currentIndex];

  bool get _isCover => _coverPhotoId != null && _coverPhotoId == _currentPhoto.photoId;

  Future<void> _setCover() async {
    final coupleId = widget.appUser.coupleId;
    if (coupleId == null || coupleId.isEmpty) return;
    await AlbumService.setCoverPhoto(
      coupleId: coupleId,
      albumId: widget.album.albumId,
      coverPhotoId: _currentPhoto.photoId,
      coverPhotoUrl: _currentPhoto.imageUrl,
    );
    if (!mounted) return;
    setState(() {
      _coverPhotoId = _currentPhoto.photoId;
    });
  }

  Future<void> _download() async {
    if (_downloading) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _downloading = true);
    try {
      await downloadImageFromUrl(
        _currentPhoto.imageUrl,
        fileName: 'album_${_currentPhoto.photoId}.jpg',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.saveStarted),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saveFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final coupleId = widget.appUser.coupleId;
    if (coupleId == null || coupleId.isEmpty) return;

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
    if (ok != true || !mounted) return;

    final deletedId = _currentPhoto.photoId;
    final removedIndex = _currentIndex;

    await AlbumService.deletePhoto(
      coupleId: coupleId,
      albumId: widget.album.albumId,
      photoId: deletedId,
    );
    if (!mounted) return;

    setState(() {
      _photos.removeAt(removedIndex);
      if (_coverPhotoId == deletedId) {
        _coverPhotoId = null;
      }
    });

    if (_photos.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final newIndex = removedIndex >= _photos.length
        ? _photos.length - 1
        : removedIndex;
    _currentIndex = newIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(newIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final coupleId = widget.appUser.coupleId;
    if (coupleId == null || coupleId.isEmpty) {
      return Scaffold(
        body: Center(child: Text(l10n.albumNoCouple)),
      );
    }

    if (_photos.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.photoViewerTitleBar)),
        body: const Center(child: Text('')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${l10n.photoViewerTitleBar} (${_currentIndex + 1}/${_photos.length})',
        ),
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
            child: PageView.builder(
              controller: _pageController,
              itemCount: _photos.length,
              onPageChanged: (i) {
                setState(() => _currentIndex = i);
              },
              itemBuilder: (context, index) {
                final url = _photos[index].imageUrl;
                return Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Material(
              color: const Color(0xFFFDF8FC),
              elevation: 8,
              shadowColor: const Color(0x33000000),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Tooltip(
                      message: l10n.setCoverImage,
                      child: _AlbumViewerActionChip(
                        icon: Icons.star_rounded,
                        active: _isCover,
                        onPressed: _isCover ? null : _setCover,
                      ),
                    ),
                    Tooltip(
                      message: l10n.delete,
                      child: _AlbumViewerActionChip(
                        icon: Icons.delete_outline_rounded,
                        onPressed: _delete,
                      ),
                    ),
                    Tooltip(
                      message: l10n.downloadTooltip,
                      child: _AlbumViewerActionChip(
                        icon: Icons.download_rounded,
                        onPressed: _downloading ? null : _download,
                        child: _downloading
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFFE98ABF),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 하단 3버튼(대표·삭제·다운로드) 공통 스타일
class _AlbumViewerActionChip extends StatelessWidget {
  const _AlbumViewerActionChip({
    required this.icon,
    this.onPressed,
    this.active = false,
    this.child,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? const Color(0x33E98ABF)
          : const Color(0xFFF5E6EC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 88,
          height: 56,
          child: Center(
            child: child ??
                Icon(
                  icon,
                  size: 28,
                  color: const Color(0xFF7A627F),
                ),
          ),
        ),
      ),
    );
  }
}
