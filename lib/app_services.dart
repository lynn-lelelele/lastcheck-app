import 'package:flutter/widgets.dart';

import 'repositories/local_repo.dart';
import 'services/checklist_service.dart';
import 'services/place_service.dart';

/// 应用级服务容器：main() 里初始化一次，页面通过 ServicesScope 访问。
class AppServices {
  final LocalRepo repo;
  final PlaceService places;
  final ChecklistService checklist;

  AppServices._(this.repo, this.places, this.checklist);

  static Future<AppServices> create() async {
    final repo = await LocalRepo.create();
    final places = PlaceService(repo);
    return AppServices._(repo, places, ChecklistService(places));
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
