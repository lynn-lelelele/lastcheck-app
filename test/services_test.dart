import 'package:flutter_test/flutter_test.dart';
import 'package:lastcheck_app/models/place.dart';
import 'package:lastcheck_app/repositories/local_repo.dart';
import 'package:lastcheck_app/services/checklist_service.dart';
import 'package:lastcheck_app/services/message_service.dart';
import 'package:lastcheck_app/services/place_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Place makePlace(String id, String name, {double radius = 100}) => Place(
      id: id,
      name: name,
      latitude: 28.228209,
      longitude: 112.938814,
      radius: radius,
    );

void main() {
  late LocalRepo repo;
  late PlaceService places;
  late ChecklistService checklist;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = await LocalRepo.create();
    places = PlaceService(repo);
    checklist = ChecklistService(places);
  });

  group('PlaceService', () {
    test('add / list / findById', () {
      places.add(makePlace('p1', '家'));
      places.add(makePlace('p2', '公司'));
      expect(places.list().length, 2);
      expect(places.findById('p1')!.name, '家');
      expect(places.findById('nope'), isNull);
    });

    test('update 使用 transform', () {
      places.add(makePlace('p1', '家'));
      places.update('p1', (p) => p.copyWith(radius: 300, items: ['钥匙', '手机']));
      final p = places.findById('p1')!;
      expect(p.radius, 300);
      expect(p.items, ['钥匙', '手机']);
    });

    test('remove', () {
      places.add(makePlace('p1', '家'));
      places.remove('p1');
      expect(places.list(), isEmpty);
    });

    test('getCurrentPlace 自动回退到第一个', () {
      places.add(makePlace('p1', '家'));
      places.add(makePlace('p2', '公司'));
      places.setCurrentPlaceId('missing');
      expect(places.getCurrentPlace()!.id, 'p1');
      expect(places.getCurrentPlaceId(), 'p1');
    });

    test('持久化：重新创建 repo 数据仍在', () async {
      places.add(makePlace('p1', '家'));
      final repo2 = await LocalRepo.create();
      expect(PlaceService(repo2).list().length, 1);
    });
  });

  group('ChecklistService', () {
    test('addItem / setCheckedMap / removeItem 重排勾选', () {
      places.add(makePlace('p1', '家'));
      checklist.setItems('p1', ['钥匙', '手机', '钱包']);
      checklist.setCheckedMap('p1', {0: true, 1: false, 2: true});
      // 删除 index=1（手机），勾选状态应重排为 {0: true, 1: true}
      final r = checklist.removeItem('p1', 1)!;
      expect(r.items, ['钥匙', '钱包']);
      expect(r.checkedMap, {0: true, 1: true});
    });

    test('未找到地点返回空', () {
      final cl = checklist.getChecklist('nope');
      expect(cl.items, isEmpty);
      expect(cl.checkedMap, isEmpty);
    });
  });

  group('MessageService', () {
    test('酒店场景文案', () {
      final p = makePlace('p1', '长沙五一广场亚朵酒店');
      final msg = buildLeaveMessage(p, ['身份证', '房卡']);
      expect(msg, contains('是在旅游吗'));
      expect(msg, contains('身份证、房卡'));
    });

    test('公司场景文案', () {
      final p = makePlace('p2', '科技园办公楼');
      final msg = buildLeaveMessage(p, []);
      expect(msg, contains('去上班吗'));
      expect(msg, contains('别忘了检查随身物品'));
    });

    test('家庭场景文案', () {
      final p = makePlace('p3', '家');
      final msg = buildLeaveMessage(p, ['钥匙']);
      expect(msg, contains('出门顺利'));
      expect(msg, contains('钥匙'));
    });
  });
}
