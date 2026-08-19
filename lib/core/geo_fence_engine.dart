import '../models/place.dart';
import 'geofence.dart';

/// 围栏事件：type 为 'leave'（离开围栏）或 'enter'（进入围栏）。
class GeoFenceEvent {
  final String type;
  final Place place;
  const GeoFenceEvent(this.type, this.place);
}

/// 围栏状态机：跟踪每个地点的进出状态，检测「离开围栏」事件。
/// 纯逻辑，可脱离 Flutter 环境单测。对应小程序版 core/geoFenceEngine.js。
class GeoFenceEngine {
  final Map<String, bool> _states = {};
  final List<void Function(GeoFenceEvent)> _listeners = [];

  /// 用最新坐标更新所有地点，返回本次产生的事件列表，并通知监听器。
  List<GeoFenceEvent> update(List<Place> places, double lat, double lng) {
    final events = <GeoFenceEvent>[];
    for (final place in places) {
      final inside = isInside(place, lat, lng);
      final prev = _states[place.id];
      if (prev == null) {
        _states[place.id] = inside;
      } else if (prev && !inside) {
        // 从围栏内到围栏外：离开事件
        events.add(GeoFenceEvent('leave', place));
        _states[place.id] = false;
      } else if (!prev && inside) {
        _states[place.id] = true;
      }
    }
    for (final ev in events) {
      for (final fn in _listeners) {
        fn(ev);
      }
    }
    return events;
  }

  void onEvent(void Function(GeoFenceEvent) fn) {
    _listeners.add(fn);
  }

  void reset() {
    _states.clear();
  }
}
