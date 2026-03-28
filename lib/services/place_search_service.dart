import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/place_search_models.dart';
import 'app_config.dart';
import 'places_js_stub.dart' if (dart.library.html) 'places_js_web.dart' as places_web;

/// 장소 검색(자동완성) + 상세 좌표 (웹: Maps JS Places, 모바일: Places REST)
class PlaceSearchService {
  PlaceSearchService._();

  static Future<List<PlaceSuggestion>> autocomplete(String input) async {
    final q = input.trim();
    if (q.length < 2) return [];

    if (kIsWeb) {
      return places_web.placesAutocomplete(q);
    }

    final key = AppConfig.googleMapsApiKey.trim();
    if (key.isEmpty) return [];

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      <String, String>{
        'input': q,
        'key': key,
        'language': 'ko',
      },
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      if (map['status'] != 'OK' && map['status'] != 'ZERO_RESULTS') {
        return [];
      }
      final preds = map['predictions'] as List<dynamic>? ?? [];
      return preds
          .whereType<Map<String, dynamic>>()
          .map((p) {
            final desc = p['description'] as String?;
            final pid = p['place_id'] as String?;
            if (desc == null || pid == null) return null;
            return PlaceSuggestion(description: desc, placeId: pid);
          })
          .whereType<PlaceSuggestion>()
          .take(8)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<PlacePickResult?> placeDetails(String placeId) async {
    if (kIsWeb) {
      return places_web.placesDetails(placeId);
    }

    final key = AppConfig.googleMapsApiKey.trim();
    if (key.isEmpty) return null;

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      <String, String>{
        'place_id': placeId,
        'key': key,
        'language': 'ko',
        'fields': 'geometry,name,formatted_address',
      },
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      if (map['status'] != 'OK') return null;
      final result = map['result'] as Map<String, dynamic>?;
      if (result == null) return null;
      final geo = result['geometry'] as Map<String, dynamic>?;
      final loc = geo?['location'] as Map<String, dynamic>?;
      final lat = (loc?['lat'] as num?)?.toDouble();
      final lng = (loc?['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      final name = (result['name'] as String?)?.trim() ?? '';
      final addr = (result['formatted_address'] as String?)?.trim() ?? '';
      final label = name.isNotEmpty ? name : addr;
      if (label.isEmpty) return null;
      return PlacePickResult(
        position: LatLng(lat, lng),
        label: label,
      );
    } catch (_) {
      return null;
    }
  }
}
