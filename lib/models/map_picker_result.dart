import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 지도에서 위치 선택 후 [Plan] 등에 넘길 때 좌표 + 표시/저장용 이름(주소 등)
class MapPickerResult {
  const MapPickerResult({
    required this.position,
    required this.label,
  });

  final LatLng position;
  /// 역지오코딩된 주소 또는 장소 설명
  final String label;
}
