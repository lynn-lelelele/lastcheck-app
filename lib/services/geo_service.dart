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
      // 只要具体单位/小区名，不拼一长串省市区
      String? short;
      if (p.name != null && p.name!.isNotEmpty) {
        short = p.name;
      } else if (p.street != null && p.street!.isNotEmpty) {
        short = p.street;
      } else if (p.subLocality != null && p.subLocality!.isNotEmpty) {
        short = p.subLocality;
      }
      if (short == null || short.isEmpty) return null;
      return GeoResult(short, p.name);
    } catch (_) {
      return null;
    }
  }
}

