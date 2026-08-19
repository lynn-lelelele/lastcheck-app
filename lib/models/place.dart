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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'items': items,
        'checkedMap': checkedMap.map((k, v) => MapEntry(k.toString(), v)),
        'sceneType': sceneType,
        'poiName': poiName,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      address: (json['address'] as String?) ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: ((json['radius'] as num?) ?? 100).toDouble(),
      items: ((json['items'] as List?) ?? []).cast<String>(),
      checkedMap: ((json['checkedMap'] as Map?) ?? {})
          .map((k, v) => MapEntry(int.parse(k as String), v as bool)),
      sceneType: json['sceneType'] as String?,
      poiName: json['poiName'] as String?,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}
