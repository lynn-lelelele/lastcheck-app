import 'package:geocoding/geocoding.dart';

/// 逆地理编码结果。
class GeoResult {
  final String address;
  final String? poiName;
  const GeoResult(this.address, this.poiName);
}

/// 地址解析服务：把坐标翻译成具体位置名称。
/// 优先用系统内置地理编码（国内 ROM 一般内置高德/百度，无需申请 key）。
class GeoService {
  static Future<GeoResult?> reverseGeocode(double lat, double lng) async {
    try {
      final marks = await Geocoding().placemarkFromCoordinates(lat, lng);
      if (marks.isEmpty) return null;
      final p = marks.first;
      final parts = <String>[
        if (p.name != null && p.name!.isNotEmpty) p.name!,
        if (p.street != null && p.street!.isNotEmpty) p.street!,
        if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
        if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
          p.administrativeArea!,
      ];
      if (parts.isEmpty) return null;
      return GeoResult(parts.join(' '), p.name);
    } catch (_) {
      return null;
    }
  }
}
