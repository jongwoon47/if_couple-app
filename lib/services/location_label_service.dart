import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'app_config.dart';
import 'geocode_web_impl_stub.dart'
    if (dart.library.html) 'geocode_web_impl_web.dart';

/// 좌표 → 사람이 읽을 수 있는 주소/장소 문자열 (역지오코딩)
class LocationLabelService {
  LocationLabelService._();

  static Future<String> labelForLatLng(LatLng position) async {
    // 웹: index.html의 Maps JS API Geocoder (REST는 CORS로 실패할 수 있음)
    if (kIsWeb) {
      final fromJs = await reverseGeocodeWeb(position);
      if (fromJs != null && fromJs.trim().isNotEmpty) {
        return fromJs.trim();
      }
    }

    if (AppConfig.hasGoogleMapsApiKey) {
      final geo = await _reverseGeocodeGoogle(position);
      final nearby = await _nearbyPlaceNameRest(position);
      final merged = (nearby != null && nearby.trim().isNotEmpty)
          ? nearby.trim()
          : geo?.trim();
      if (merged != null && merged.isNotEmpty) {
        return merged;
      }
    }

    if (!kIsWeb) {
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[];
          void add(String? s) {
            final t = s?.trim();
            if (t != null && t.isNotEmpty && !parts.contains(t)) parts.add(t);
          }
          add(p.name);
          add(p.street);
          add(p.locality);
          add(p.subAdministrativeArea);
          add(p.administrativeArea);
          add(p.country);
          if (parts.isNotEmpty) return parts.join(' ');
        }
      } catch (_) {}
    }

    return '위치 ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
  }

  /// Places Nearby — 탭 좌표 근처 시설명 (공원·관광 등). Geocoding만으로는 지번만 나올 때 보완.
  static Future<String?> _nearbyPlaceNameRest(LatLng position) async {
    final key = AppConfig.googleMapsApiKey.trim();
    if (key.isEmpty) return null;

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/nearbysearch/json',
      <String, String>{
        'location': '${position.latitude},${position.longitude}',
        'radius': '100',
        'key': key,
        'language': 'ko',
      },
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      if (map['status'] != 'OK' && map['status'] != 'ZERO_RESULTS') {
        return null;
      }
      final rawList = map['results'] as List<dynamic>? ?? [];
      if (rawList.isEmpty) return null;

      LatLng? locFromGeometry(Map<String, dynamic>? g) {
        if (g == null) return null;
        final loc = g['location'] as Map<String, dynamic>?;
        if (loc == null) return null;
        final la = (loc['lat'] as num?)?.toDouble();
        final ln = (loc['lng'] as num?)?.toDouble();
        if (la == null || ln == null) return null;
        return LatLng(la, ln);
      }

      const goodTypes = <String>{
        'park',
        'natural_feature',
        'tourist_attraction',
        'point_of_interest',
        'establishment',
      };

      final goodList = <({Map<String, dynamic> raw, double d})>[];
      final anyList = <({Map<String, dynamic> raw, double d})>[];

      for (final raw in rawList) {
        if (raw is! Map<String, dynamic>) continue;
        final geo = raw['geometry'] as Map<String, dynamic>?;
        final loc = locFromGeometry(geo);
        if (loc == null) continue;
        final d = _haversineMeters(position, loc);
        if (d > 72) continue;
        final name = (raw['name'] as String?)?.trim() ?? '';
        if (name.isEmpty || _isLikelyStreetFragment(name)) continue;
        final types = (raw['types'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final hasGood = types.any(goodTypes.contains);
        if (hasGood && d < 65) goodList.add((raw: raw, d: d));
        if (d < 50) anyList.add((raw: raw, d: d));
      }

      goodList.sort((a, b) => a.d.compareTo(b.d));
      if (goodList.isNotEmpty) {
        return (goodList.first.raw['name'] as String?)?.trim();
      }
      anyList.sort((a, b) => a.d.compareTo(b.d));
      if (anyList.isNotEmpty && anyList.first.d < 38) {
        return (anyList.first.raw['name'] as String?)?.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static double _haversineMeters(LatLng a, LatLng b) {
    const earth = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earth * math.asin(math.min(1.0, math.sqrt(h)));
  }

  static double _rad(double d) => d * math.pi / 180.0;

  static Future<String?> _reverseGeocodeGoogle(LatLng position) async {
    final key = AppConfig.googleMapsApiKey.trim();
    if (key.isEmpty) return null;

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      <String, String>{
        'latlng': '${position.latitude},${position.longitude}',
        'key': key,
        'language': 'ko',
      },
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      if (map['status'] != 'OK') return null;
      final results = map['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      return _labelFromGeocodeResults(results);
    } catch (_) {
      return null;
    }
  }

  /// 번지(8-51)·동호 등 — 시설명으로 쓰지 않음
  static bool _isLikelyStreetFragment(String s) {
    final t = s.trim();
    if (t.isEmpty) return true;
    if (RegExp(r'^\d+$').hasMatch(t)) return true;
    if (RegExp(r'^\d{1,5}-\d{1,5}(-\d{1,5})?$').hasMatch(t)) return true;
    if (RegExp(r'^\d{1,5}동(\s*\d{1,5}호)?$').hasMatch(t)) return true;
    if (t.length < 18 && RegExp(r'^[\d\s\-]+$').hasMatch(t)) return true;
    return false;
  }

  static bool _resultTypesHasPoi(Map<String, dynamic> item) {
    final rt = item['types'] as List<dynamic>?;
    if (rt == null) return false;
    const poi = <String>{
      'point_of_interest',
      'establishment',
      'park',
      'natural_feature',
      'tourist_attraction',
    };
    for (final e in rt) {
      if (poi.contains(e.toString())) return true;
    }
    return false;
  }

  /// 여러 geocode result 중 시설명·주소 우선 (8-51 같은 subpremise는 뒤로)
  static String? _labelFromGeocodeResults(List<dynamic> results) {
    bool isNumericOnly(String s) {
      final t = s.trim();
      return t.isNotEmpty && RegExp(r'^\d+$').hasMatch(t);
    }

    String? nameFromComponents(
      List<dynamic>? components,
      Set<String> typesWanted, {
      required bool allowPremise,
    }) {
      if (components == null) return null;
      for (final c in components) {
        if (c is! Map<String, dynamic>) continue;
        final types = (c['types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        for (final tw in typesWanted) {
          if (types.contains(tw)) {
            final n = (c['long_name'] as String?)?.trim() ?? '';
            if (n.isEmpty) continue;
            if (isNumericOnly(n)) continue;
            if (allowPremise && (tw == 'premise' || tw == 'subpremise')) {
              if (_isLikelyStreetFragment(n)) continue;
            }
            if (!allowPremise && (tw == 'premise' || tw == 'subpremise')) {
              continue;
            }
            if (_isLikelyStreetFragment(n)) continue;
            return n;
          }
        }
      }
      return null;
    }

    const poiTypes = {
      'point_of_interest',
      'establishment',
      'park',
      'natural_feature',
      'tourist_attraction',
    };
    const premiseTypes = {'premise', 'subpremise'};

    // 1) POI로 분류된 result: 시설명 → formatted_address
    for (final item in results) {
      if (item is! Map<String, dynamic>) continue;
      if (!_resultTypesHasPoi(item)) continue;
      final comps = item['address_components'] as List<dynamic>?;
      final poi = nameFromComponents(comps, poiTypes, allowPremise: false);
      if (poi != null) return poi;
      final fa = item['formatted_address'] as String?;
      if (fa != null && fa.trim().isNotEmpty) return fa.trim();
    }
    // 2) 모든 result에서 POI 컴포넌트
    for (final item in results) {
      if (item is! Map<String, dynamic>) continue;
      final comps = item['address_components'] as List<dynamic>?;
      final poi = nameFromComponents(comps, poiTypes, allowPremise: false);
      if (poi != null) return poi;
    }
    // 3) 전체 주소
    for (final item in results) {
      if (item is! Map<String, dynamic>) continue;
      final fa = item['formatted_address'] as String?;
      if (fa != null && fa.trim().isNotEmpty) return fa.trim();
    }
    // 4) premise (번지 패턴 제외)
    for (final item in results) {
      if (item is! Map<String, dynamic>) continue;
      final comps = item['address_components'] as List<dynamic>?;
      final pr = nameFromComponents(comps, premiseTypes, allowPremise: true);
      if (pr != null) return pr;
    }
    return null;
  }
}
