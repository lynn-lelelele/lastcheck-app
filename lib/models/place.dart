/// 常去地点：对应小程序版 models/Place（ARCHITECTURE.md 第 5 章）。
class Place {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double radius;
  final List<String> items;
  final Map<int, bool> checkedMap;
  final String? sceneType; // home/office/hotel/restaurant/gym/other
  final String? poiName;
  final DateTime createdAt;

  Place({
    required this.id,
    required this.name,
    this.address = '',
    required this.latitude,
    required this.longitude,
    this.radius = 100,
    this.items = const [],
    this.checkedMap = const {},
    this.sceneType,
    this.poiName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Place copyWith({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    double? radius,
    List<String>? items,
    Map<int, bool>? checkedMap,
    String? sceneType,
    String? poiName,
  }) {
    return Place(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      items: items ?? this.items,
      checkedMap: checkedMap ?? this.checkedMap,
      sceneType: sceneType ?? this.sceneType,
      poiName: poiName ?? this.poiName,
      createdAt: createdAt,
    );
  }
}
