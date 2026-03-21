import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/download_network_image.dart';

/// 채팅 등에서 네트워크 이미지를 탭했을 때 전체 화면으로 확대(핀치 줌) · 닫기 · 다운로드
class FullscreenNetworkImageViewer {
  FullscreenNetworkImageViewer._();

  static Future<void> show(BuildContext context, String imageUrl) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      useSafeArea: false,
      builder: (ctx) => _DialogBody(imageUrl: imageUrl),
    );
  }
}

class _DialogBody extends StatefulWidget {
  const _DialogBody({required this.imageUrl});

  final String imageUrl;

  @override
  State<_DialogBody> createState() => _DialogBodyState();
}

class _DialogBodyState extends State<_DialogBody> {
  bool _downloading = false;

  Future<void> _onDownload() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      await downloadImageFromUrl(widget.imageUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.saveStarted),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.saveFailed(e.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5,
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white70,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    tooltip: l10n.closeTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  IconButton(
                    icon: _downloading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          )
                        : const Icon(Icons.download_rounded, color: Colors.white, size: 28),
                    tooltip: l10n.downloadTooltip,
                    onPressed: _downloading ? null : _onDownload,
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
