import '../models/place.dart';
import 'place_service.dart';

/// 出门清单服务：清单物品的读取、添加、删除、勾选状态。
/// 对应小程序版 services/checklistService.js。
class ChecklistService {
  final PlaceService _places;

  ChecklistService(this._places);

  ({List<String> items, Map<int, bool> checkedMap}) getChecklist(String placeId) {
    final p = _places.findById(placeId);
    if (p == null) return (items: [], checkedMap: {});
    return (items: p.items, checkedMap: p.checkedMap);
  }

  void setItems(String placeId, List<String> items) {
    _places.update(placeId, (p) => p.copyWith(items: items));
  }

  void setCheckedMap(String placeId, Map<int, bool> checkedMap) {
    _places.update(placeId, (p) => p.copyWith(checkedMap: checkedMap));
  }

  List<String>? addItem(String placeId, String name) {
    final p = _places.findById(placeId);
    if (p == null) return null;
    final items = [...p.items, name];
    setItems(placeId, items);
    return items;
  }

  /// 删除物品并重排勾选状态。
  ({List<String> items, Map<int, bool> checkedMap})? removeItem(
      String placeId, int index) {
    final p = _places.findById(placeId);
    if (p == null) return null;
    final items = [...p.items];
    final old = p.checkedMap;
    items.removeAt(index);
    final checkedMap = <int, bool>{};
    for (var j = 0; j < items.length; j++) {
      checkedMap[j] = j < index ? (old[j] ?? false) : (old[j + 1] ?? false);
    }
    setItems(placeId, items);
    setCheckedMap(placeId, checkedMap);
    return (items: items, checkedMap: checkedMap);
  }
}
