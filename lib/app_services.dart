import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

import 'repositories/local_repo.dart';
import 'services/checklist_service.dart';
import 'services/geofence_service.dart';
import 'services/notification_service.dart';
import 'services/place_service.dart';

/// 应用级服务容器：main() 里初始化一次，页面通过 ServicesScope 访问。
class AppServices {
  final LocalRepo repo;
  final PlaceService places;
  final ChecklistService checklist;
  final NotificationService notifications;
  final GeofenceService geofence;

  AppServices._(
      this.repo, this.places, this.checklist, this.notifications, this.geofence);

  static Future<AppServices> create() async {
    final repo = await LocalRepo.create();
    final places = PlaceService(repo);
    final notifications = NotificationService();
    await notifications.init();
    final geofence = GeofenceService();
    await geofence.init();
    final svc = AppServices._(
        repo, places, ChecklistService(places), notifications, geofence);
    // 启动时把已有地点同步为系统围栏
    await geofence.sync(places.list());
    // 预热定位：让系统定位提供方开始工作（也便于围栏事件及时触发）
    unawaited(() async {
      try {
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
        );
      } catch (_) {}
    }());
    return svc;
  }
}

/// InheritedWidget：让页面不靠构造参数层层传递服务。
class ServicesScope extends InheritedWidget {
  final AppServices services;
  const ServicesScope({super.key, required this.services, required super.child});

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ServicesScope>();
    assert(scope != null, 'ServicesScope not found');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(ServicesScope oldWidget) =>
      services != oldWidget.services;
}

/// 全局轻量事件：tab 切换、演示出门提醒。
class AppEvents {
  AppEvents._();
  static final tabIndex = ValueNotifier<int>(0);
  static final demoRemind = ValueNotifier<int>(0);
}


