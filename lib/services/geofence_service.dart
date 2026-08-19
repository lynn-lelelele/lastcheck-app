import 'package:flutter/foundation.dart';
import 'package:native_geofence/native_geofence.dart';

import '../models/place.dart';
import '../repositories/local_repo.dart';
import '../services/place_service.dart';
import 'message_service.dart';
import 'notification_service.dart';

/// 系统级地理围栏服务（Android GeofencingClient / iOS CLCircularRegion）。
/// 负责把「常去地点」注册为围栏，并在离开围栏时触发提醒。
class GeofenceService {
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await NativeGeofenceManager.instance.initialize();
      _initialized = true;
      debugPrint('[LastCheck] geofence initialized');
    } catch (e) {
      debugPrint('[LastCheck] geofence init failed: $e');
    }
  }

  /// 按当前地点列表重建围栏（简单可靠：先清空再注册）。
  Future<void> sync(List<Place> places) async {
    if (!_initialized) return;
    try {
      await NativeGeofenceManager.instance.removeAllGeofences();
      for (final p in places) {
        await NativeGeofenceManager.instance.createGeofence(
          Geofence(
            id: p.id,
            location: Location(latitude: p.latitude, longitude: p.longitude),
            radiusMeters: p.radius,
            triggers: {GeofenceEvent.exit},
            androidSettings: AndroidGeofenceSettings(
              initialTriggers: {GeofenceEvent.exit},
              expiration: const Duration(days: 30),
            ),
            iosSettings: IosGeofenceSettings(),
          ),
          geofenceTriggered,
        );
      }
      debugPrint('[LastCheck] geofences synced: ${places.length}');
    } catch (e) {
      debugPrint('[LastCheck] geofence sync failed: $e');
    }
  }

  /// 当前已注册的围栏数量（诊断用）。
  Future<int> getRegisteredCount() async {
    if (!_initialized) return 0;
    try {
      final ids =
          await NativeGeofenceManager.instance.getRegisteredGeofenceIds();
      return ids.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> clearAll() async {
    if (!_initialized) return;
    try {
      await NativeGeofenceManager.instance.removeAllGeofences();
      debugPrint('[LastCheck] geofences cleared');
    } catch (e) {
      debugPrint('[LastCheck] geofence clear failed: $e');
    }
  }
}

/// 围栏触发回调（可能运行在后台 isolate，App 被杀时也会被系统拉起执行）。
/// 只处理「离开围栏」事件：查出该地点的未确认项，弹系统通知。
@pragma('vm:entry-point')
Future<void> geofenceTriggered(GeofenceCallbackParams params) async {
  if (params.event != GeofenceEvent.exit) return;
  debugPrint('[LastCheck] geofence exit: ${params.geofences.map((g) => g.id).join(',')}');

  final notif = NotificationService();
  await notif.init();

  for (final zone in params.geofences) {
    try {
      final repo = await LocalRepo.create();
      final place = PlaceService(repo).findById(zone.id);
      if (place == null) continue;
      final pending = [
        for (var i = 0; i < place.items.length; i++)
          if (!(place.checkedMap[i] ?? false)) place.items[i],
      ];
      final content = buildLeaveMessage(place, pending);
      await notif.showReminder(place.name, content);
      debugPrint('[LastCheck] reminder sent for ${place.name}');
    } catch (e) {
      debugPrint('[LastCheck] geofence callback error: $e');
    }
  }
}

