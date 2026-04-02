import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../../models/app_user.dart';
import '../../models/album_models.dart';
import '../../services/album_service.dart';
import '../../services/firebase_error_messages.dart';

class AlbumEditScreen extends StatefulWidget {
  const AlbumEditScreen({
    super.key,
    required this.appUser,
    this.existingAlbum,
  });

  final AppUser appUser;
  final Album? existingAlbum;

  @override
  State<AlbumEditScreen> createState() => _AlbumEditScreenState();
}

class _AlbumEditScreenState extends State<AlbumEditScreen> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();

  final _picker = ImagePicker();
  final List<XFile> _pickedImages = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final album = widget.existingAlbum;
    if (album != null) {
      _titleController.text = album.title;
      _memoController.text = album.memo;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  int _currentCount() => widget.existingAlbum?.photoCount ?? 0;

  int _remainingLimit() {
    final max = AlbumService.maxPhotosPerAlbumFree;
    final used = _currentCount() + _pickedImages.length;
    return (max - used).clamp(0, max);
  }

  Future<void> _pickImages() async {
    final l10n = AppLocalizations.of(context)!;
    final remaining = _remainingLimit();
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.albumMaxPhotos)),
      );
      return;
    }

    try {
      final files = await _picker.pickMultiImage(
        limit: remaining,
        imageQuality: 85,
      );
      if (!mounted) return;
      if (files.isEmpty) return;
      setState(() {
        _pickedImages.addAll(files);
      });
    } catch (e) {
      // 웹에서 pickMultiImage가 지원되지 않는 경우 등
      if (kIsWeb) {
        try {
          final one = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
            maxWidth: 4096,
            maxHeight: 4096,
          );
          if (!mounted) return;
          if (one != null) {
            setState(() => _pickedImages.add(one));
          }
          return;
        } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.albumLoadImageFailed(e.toString()))),
      );
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;

    final coupleId = widget.appUser.coupleId;
    if (coupleId == null || coupleId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.albumNoCouple)),
      );
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.albumTitleRequired)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      Album album;

      if (widget.existingAlbum == null) {
        // 우선 앨범을 만들고(대표는 업로드 후 결정)
        album = await AlbumService.createAlbum(
          coupleId: coupleId,
          title: title,
          memo: _memoController.text,
          coverPhotoId: null,
          coverPhotoUrl: null,
        );
      } else {
        album = widget.existingAlbum!;
        await AlbumService.updateAlbum(
          coupleId: coupleId,
          album: Album(
            albumId: album.albumId,
            coupleId: coupleId,
            title: title,
            memo: _memoController.text,
            coverPhotoId: album.coverPhotoId,
            coverPhotoUrl: album.coverPhotoUrl,
            photoCount: album.photoCount,
            createdAt: album.createdAt,
            updatedAt: now,
          ),
        );
      }

      if (_pickedImages.isNotEmpty) {
        final bytesList = <List<int>>[];
        final fileNames = <String>[];
        for (final x in _pickedImages) {
          final b = await x.readAsBytes();
          bytesList.add(b);
          fileNames.add(x.name);
        }

        await AlbumService.uploadPhotos(
          coupleId: coupleId,
          albumId: album.albumId,
          uploadedByUserId: widget.appUser.userId,
          bytesList: bytesList,
          fileNames: fileNames,
        );
        // 대표(썸네일) 자동 설정은 AlbumService.uploadPhotos 안에서 처리
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messageForUploadFailure(e, AppLocalizations.of(context)!)),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.existingAlbum != null;
    final title = isEditing ? l10n.albumEditTitle : l10n.albumAddTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? l10n.saving : l10n.save),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.albumTitleLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _memoController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.albumMemoLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickImages,
                icon: const Icon(Icons.photo_library_rounded),
                label: Text(
                  _remainingLimit() <= 0
                      ? l10n.albumPhotoAddDisabled
                      : l10n.albumPhotoAddRemaining(_remainingLimit()),
                ),
              ),
              const SizedBox(height: 14),
              if (_pickedImages.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pickedImages.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final x = _pickedImages[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: FutureBuilder(
                        future: x.readAsBytes(),
                        builder: (context, snap) {
                          if (snap.connectionState != ConnectionState.done) {
                            return const ColoredBox(
                              color: Color(0xFFF0E7F0),
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }
                          if (!snap.hasData) {
                            return const ColoredBox(
                              color: Color(0xFFF0E7F0),
                              child: Icon(Icons.broken_image_rounded),
                            );
                          }
                          return Image.memory(
                            snap.data!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          );
                        },
                      ),
                    );
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.albumPreviewHint,
                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

