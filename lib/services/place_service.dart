import '../models/place.dart';
import '../repositories/local_repo.dart';

/// 常去地点服务：地点的增删改查与当前地点状态。
/// 对应小程序版 services/placeService.js。
class PlaceService {
  final LocalRepo _repo;

  PlaceService(this._repo);

  List<Place> list() => _repo.getPlaces();

  Place? findById(String id) {
    for (final p in list()) {
      if (p.id == id) return p;
    }
    return null;
  }

  Place add(Place place) {
    final places = _repo.getPlaces();
    places.add(place);
    _repo.savePlaces(places);
    return place;
  }

  void remove(String id) {
    _repo.savePlaces(_repo.getPlaces().where((p) => p.id != id).toList());
  }

  /// 用 [transform] 生成新对象替换指定地点，返回更新后的对象；不存在返回 null。
  Place? update(String id, Place Function(Place) transform) {
    final places = _repo.getPlaces();
    final i = places.indexWhere((p) => p.id == id);
    if (i == -1) return null;
    places[i] = transform(places[i]);
    _repo.savePlaces(places);
    return places[i];
  }

  String getCurrentPlaceId() => _repo.getCurrentPlaceId();

  void setCurrentPlaceId(String id) => _repo.setCurrentPlaceId(id);

  /// 获取当前地点（无则回退到第一个）。
  Place? getCurrentPlace() {
    final places = list();
    if (places.isEmpty) return null;
    var id = getCurrentPlaceId();
    if (!places.any((p) => p.id == id)) {
      id = places.first.id;
      setCurrentPlaceId(id);
    }
    return findById(id);
  }
}
