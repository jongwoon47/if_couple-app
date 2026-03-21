// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import '../models/place_search_models.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

@JS('ifAppPlacesPredictionsAsync')
external void _ifAppPlacesPredictionsAsync(JSString input, JSFunction callback);

@JS('ifAppPlaceDetailsAsync')
external void _ifAppPlaceDetailsAsync(JSString placeId, JSFunction callback);

Future<List<PlaceSuggestion>> placesAutocomplete(String input) {
  final c = Completer<List<PlaceSuggestion>>();
  void onDone(JSAny? value) {
    if (c.isCompleted) return;
    try {
      final s = (value as JSString).toDart;
      final decoded = jsonDecode(s);
      if (decoded is! List<dynamic>) {
        c.complete([]);
        return;
      }
      final out = <PlaceSuggestion>[];
      for (final e in decoded) {
        if (e is! Map<String, dynamic>) continue;
        final desc = e['description'] as String?;
        final pid = e['place_id'] as String?;
        if (desc != null && pid != null) {
          out.add(PlaceSuggestion(description: desc, placeId: pid));
        }
      }
      c.complete(out);
    } catch (_) {
      c.complete([]);
    }
  }

  _ifAppPlacesPredictionsAsync(input.toJS, onDone.toJS);
  return c.future;
}

Future<PlacePickResult?> placesDetails(String placeId) {
  final c = Completer<PlacePickResult?>();
  void onDone(JSAny? value) {
    if (c.isCompleted) return;
    try {
      final s = (value as JSString).toDart.trim();
      if (s.isEmpty) {
        c.complete(null);
        return;
      }
      final m = jsonDecode(s) as Map<String, dynamic>;
      final lat = (m['lat'] as num?)?.toDouble();
      final lng = (m['lng'] as num?)?.toDouble();
      final label = (m['label'] as String?)?.trim() ?? '';
      if (lat == null || lng == null || label.isEmpty) {
        c.complete(null);
        return;
      }
      c.complete(PlacePickResult(position: LatLng(lat, lng), label: label));
    } catch (_) {
      c.complete(null);
    }
  }

  _ifAppPlaceDetailsAsync(placeId.toJS, onDone.toJS);
  return c.future;
}
