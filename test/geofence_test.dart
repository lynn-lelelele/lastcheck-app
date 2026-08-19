import 'package:flutter_test/flutter_test.dart';
import 'package:lastcheck_app/core/geofence.dart';
import 'package:lastcheck_app/core/geo_fence_engine.dart';
import 'package:lastcheck_app/models/place.dart';

void main() {
  group('geofence 距离与围栏判定', () {
    test('同一点距离为 0', () {
      expect(distanceMeters(28.228209, 112.938814, 28.228209, 112.938814),
          closeTo(0, 0.001));
    });

    test('半径内 isInside 为 true', () {
      final p = Place(
          id: 'p1', name: '家', latitude: 28.228209, longitude: 112.938814, radius: 100);
      expect(isInside(p, 28.228209, 112.938814), isTrue);
      // 向南约 50m，仍在 100m 围栏内
      expect(isInside(p, 28.22776, 112.938814), isTrue);
    });

    test('围栏外 isInside 为 false', () {
      final p = Place(
          id: 'p1', name: '家', latitude: 28.228209, longitude: 112.938814, radius: 100);
      // 向北约 200m，超出 100m 围栏
      expect(isInside(p, 28.2300, 112.938814), isFalse);
    });
  });

  group('GeoFenceEngine 状态机', () {
    final place = Place(
        id: 'p1', name: '家', latitude: 28.228209, longitude: 112.938814, radius: 100);

    test('从围栏内到围栏外触发 leave', () {
      final engine = GeoFenceEngine();
      final events = <String>[];
      engine.onEvent((ev) => events.add(ev.type));

      engine.update([place], 28.228209, 112.938814); // 初始在围栏内
      expect(events, isEmpty);

      engine.update([place], 28.2300, 112.938814); // 离开
      expect(events, ['leave']);
    });

    test('持续在围栏外不重复触发（去抖）', () {
      final engine = GeoFenceEngine();
      final events = <String>[];
      engine.onEvent((ev) => events.add(ev.type));

      engine.update([place], 28.228209, 112.938814);
      engine.update([place], 28.2300, 112.938814);
      engine.update([place], 28.2310, 112.938814);
      expect(events, ['leave']);
    });

    test('重新进入围栏后可再次触发 leave', () {
      final engine = GeoFenceEngine();
      final events = <String>[];
      engine.onEvent((ev) => events.add(ev.type));

      engine.update([place], 28.228209, 112.938814);
      engine.update([place], 28.2300, 112.938814); // leave #1
      engine.update([place], 28.228209, 112.938814); // 回来
      engine.update([place], 28.2305, 112.938814); // leave #2
      expect(events, ['leave', 'leave']);
    });
  });
}
