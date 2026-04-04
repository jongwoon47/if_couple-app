import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/download_network_image.dart';

/// 채팅 등에서 네트워크 이미지를 탭했을 때 전체 화면으로 확대(핀치 줌) · 닫기 · 다운로드
///
/// [showDialog] 대신 전체 화면 [Navigator.push]를 쓰면 레이아웃이 꽉 차고
/// 상단 바에 닫기/다운로드가 항상 보입니다.
class FullscreenNetworkImageViewer {
  FullscreenNetworkImageViewer._();

  static Future<void> show(BuildContext context, String imageUrl) {
    final nav = Navigator.of(context, rootNavigator: true);
    return nav.push<void>(
      _FullscreenImageRoute(imageUrl: imageUrl),
    );
  }
}

class _FullscreenImageRoute extends PageRoute<void> {
  _FullscreenImageRoute({required this.imageUrl});

  final String imageUrl;

  @override
  Color? get barrierColor => Colors.black;

  @override
  String? get barrierLabel {
    final nav = navigator;
    if (nav == null) return 'Close';
    return MaterialLocalizations.of(nav.context).modalBarrierDismissLabel;
  }

  @override
  bool get barrierDismissible => true;

  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _ViewerScaffold(imageUrl: imageUrl);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}

class _ViewerScaffold extends StatefulWidget {
  const _ViewerScaffold({required this.imageUrl});

  final String imageUrl;

  @override
  State<_ViewerScaffold> createState() => _ViewerScaffoldState();
}

class _ViewerScaffoldState extends State<_ViewerScaffold> {
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
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 28),
          tooltip: l10n.closeTooltip,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: l10n.downloadTooltip,
            onPressed: _downloading ? null : _onDownload,
            icon: _downloading
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white70,
                    ),
                  )
                : const Icon(Icons.download_rounded, size: 28),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ColoredBox(
            color: Colors.black,
            child: InteractiveViewer(
              minScale: 0.6,
              maxScale: 5,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: Center(
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.contain,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 200,
                      width: constraints.maxWidth,
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
          );
        },
      ),
    );
  }
}
