import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/place.dart';

/// 本地存储仓库：数据读写统一入口。
/// 对应小程序版 repositories/localRepo.js；后续可替换为云仓库。
class LocalRepo {
  static const _keyPlaces = 'lastcheck_places';
  static const _keyTemplates = 'lastcheck_templates';
  static const _keyCurrentPlace = 'lastcheck_current_place_id';

  final SharedPreferences _prefs;

  LocalRepo(this._prefs);

  static Future<LocalRepo> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalRepo(prefs);
  }

  List<Place> getPlaces() {
    final raw = _prefs.getString(_keyPlaces);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => Place.fromJson(e as Map<String, dynamic>)).toList();
  }

  void savePlaces(List<Place> places) {
    _prefs.setString(_keyPlaces, jsonEncode(places.map((p) => p.toJson()).toList()));
  }

  List<Map<String, dynamic>> getTemplates() {
    final raw = _prefs.getString(_keyTemplates);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  void saveTemplates(List<Map<String, dynamic>> templates) {
    _prefs.setString(_keyTemplates, jsonEncode(templates));
  }

  String getCurrentPlaceId() => _prefs.getString(_keyCurrentPlace) ?? '';

  void setCurrentPlaceId(String id) {
    _prefs.setString(_keyCurrentPlace, id);
  }

  void clearAll() {
    _prefs.remove(_keyPlaces);
    _prefs.remove(_keyTemplates);
    _prefs.remove(_keyCurrentPlace);
  }
}
