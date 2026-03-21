// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:js_interop';

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// `web/index.html`에서 로드한 Maps JavaScript API의 Geocoder 사용.
/// 브라우저에서 Geocoding REST(http)는 CORS로 막힐 수 있어, 웹은 이 경로가 안정적입니다.
@JS('ifAppReverseGeocodeAsync')
external void _ifAppReverseGeocodeAsync(
  JSNumber lat,
  JSNumber lng,
  JSFunction callback,
);

Future<String?> reverseGeocodeWeb(LatLng position) {
  final completer = Completer<String?>();

  void onDone(JSAny? value) {
    if (completer.isCompleted) return;
    if (value == null) {
      completer.complete(null);
      return;
    }
    try {
      final s = (value as JSString).toDart.trim();
      completer.complete(s.isEmpty ? null : s);
    } catch (_) {
      completer.complete(null);
    }
  }

  _ifAppReverseGeocodeAsync(
    position.latitude.toJS,
    position.longitude.toJS,
    onDone.toJS,
  );
  return completer.future;
}
