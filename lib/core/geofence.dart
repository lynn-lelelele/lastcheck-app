import 'dart:math';

import '../models/place.dart';

/// 将角度转为弧度。
double _toRadians(double deg) => deg * pi / 180;

/// 基于 Haversine 公式计算两点球面距离（米）。
/// 对应小程序版 core/geofence.js 的 distanceMeters。
double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const R = 6371000.0;
  final dLat = _toRadians(lat2 - lat1);
  final dLng = _toRadians(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

/// 是否位于围栏内（place: {latitude, longitude, radius}）。
bool isInside(Place place, double lat, double lng) {
  return distanceMeters(place.latitude, place.longitude, lat, lng) <= place.radius;
}
