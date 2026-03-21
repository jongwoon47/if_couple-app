import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Places 자동완성 한 줄
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.description,
    required this.placeId,
  });

  final String description;
  final String placeId;
}

/// 장소 상세 → 지도에 반영
class PlacePickResult {
  const PlacePickResult({
    required this.position,
    required this.label,
  });

  final LatLng position;
  final String label;
}
