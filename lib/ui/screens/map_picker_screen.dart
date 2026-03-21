import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../models/map_picker_result.dart';
import '../../models/place_search_models.dart';
import '../../services/location_label_service.dart';
import '../../services/place_search_service.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({
    super.key,
    this.initial,
  });

  final LatLng? initial;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _selected;
  bool _saving = false;

  /// 빠른 연속 탭 시 이전 역지오코딩 결과가 덮이지 않도록
  int _tapGen = 0;
  String? _previewLabel;
  bool _loadingLabel = false;

  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _searchLoading = false;

  static const Color _appBarBg = Color(0xFFF7E9F8);
  static const Color _appBarFg = Color(0xFF5C516A);
  static const Color _accentPink = Color(0xFFE98ABF);
  static const Color _muted = Color(0xFFB3A4C0);

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    if (_selected != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onMapTap(_selected!);
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchQueryChanged(String raw) {
    _searchDebounce?.cancel();
    final q = raw.trim();
    if (q.length < 2) {
      setState(() {
        _suggestions = [];
        _searchLoading = false;
      });
      return;
    }
    setState(() => _searchLoading = true);
    _searchDebounce = Timer(const Duration(milliseconds: 380), () async {
      final list = await PlaceSearchService.autocomplete(q);
      if (!mounted) return;
      setState(() {
        _suggestions = list;
        _searchLoading = false;
      });
    });
  }

  Future<void> _selectSuggestion(PlaceSuggestion s) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _suggestions = [];
      _searchLoading = true;
    });
    final detail = await PlaceSearchService.placeDetails(s.placeId);
    if (!mounted) return;
    if (detail == null) {
      setState(() => _searchLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.mapPlaceLoadFailed)),
      );
      return;
    }
    _tapGen++; // 진행 중인 역지오코딩 무시
    setState(() {
      _searchLoading = false;
      _selected = detail.position;
      _previewLabel = detail.label;
      _loadingLabel = false;
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(detail.position, 16),
    );
  }

  void _onMapTap(LatLng pos) {
    final gen = ++_tapGen;
    setState(() {
      _selected = pos;
      _previewLabel = null;
      _loadingLabel = true;
      _suggestions = [];
    });
    LocationLabelService.labelForLatLng(pos).then((label) {
      if (!mounted || gen != _tapGen) return;
      setState(() {
        _loadingLabel = false;
        _previewLabel = label;
      });
    });
  }

  Future<void> _complete() async {
    final pos = _selected;
    if (pos == null || _saving) return;

    setState(() => _saving = true);
    try {
      final label = _previewLabel != null && _previewLabel!.trim().isNotEmpty
          ? _previewLabel!.trim()
          : await LocationLabelService.labelForLatLng(pos);
      if (!mounted) return;
      Navigator.of(context).pop<MapPickerResult>(
        MapPickerResult(position: pos, label: label),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _bottomHintText(AppLocalizations l10n) {
    if (_selected == null) {
      return l10n.mapHintTap;
    }
    if (_loadingLabel) {
      return l10n.mapHintLoading;
    }
    if (_previewLabel != null && _previewLabel!.isNotEmpty) {
      return _previewLabel!;
    }
    return l10n.mapHintSelected;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final initial = _selected ?? const LatLng(37.5665, 126.9780);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: _appBarBg,
        foregroundColor: _appBarFg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _appBarFg),
        title: Text(l10n.mapPickerTitleBar),
        actions: [
          TextButton(
            onPressed: (_selected == null || _saving) ? null : _complete,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n.mapDone,
                    style: TextStyle(
                      color: _selected == null ? _muted : _accentPink,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            elevation: 2,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (v) {
                      setState(() {});
                      _onSearchQueryChanged(v);
                    },
                    decoration: InputDecoration(
                      hintText: l10n.mapSearchHint,
                      prefixIcon: _searchLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.trim().isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _suggestions = []);
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      isDense: true,
                    ),
                  ),
                  if (_suggestions.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.only(top: 6, bottom: 8),
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final s = _suggestions[i];
                          return ListTile(
                            dense: true,
                            title: Text(
                              s.description,
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () => _selectSuggestion(s),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: initial,
                    zoom: 13,
                  ),
                  onMapCreated: (c) => _mapController = c,
                  onTap: _onMapTap,
                  markers: {
                    if (_selected != null)
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: _selected!,
                      ),
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.place_rounded,
                                color: _loadingLabel ? _muted : _accentPink,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _bottomHintText(l10n),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
