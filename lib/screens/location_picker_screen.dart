import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../core/gcj.dart';
import '../services/geo_service.dart';
import '../theme.dart';

/// 位置选择结果（WGS-84 坐标）。
class PickedLocation {
  final double latitude;
  final double longitude;
  final String source; // current / sample / map
  final String address;
  const PickedLocation(this.latitude, this.longitude, this.source,
      {this.address = ''});
}

/// 长沙示例坐标（小程序版演示位置，WGS-84）。
const kSampleLat = 28.228209;
const kSampleLng = 112.938814;

/// 全屏地图选点：高德地图瓦片 + 点按放置标记 + 当前位置 / 示例位置。
/// 自动处理 GCJ-02 偏移，点哪儿标记就落哪儿。
class LocationPickerScreen extends StatefulWidget {
  final String title;
  const LocationPickerScreen({super.key, this.title = '选择位置'});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapCtrl = MapController();

  /// 真实坐标（WGS-84，返回给上层存库）
  LatLng _wgs = const LatLng(kSampleLat, kSampleLng);
  bool _locating = false;
  String? _locateError;
  String _address = '';
  bool _resolving = false;
  int _geoToken = 0;

  /// 地图展示坐标（GCJ-02，对齐高德瓦片）
  LatLng get _display =>
      wgsToGcj(_wgs.latitude, _wgs.longitude);

  @override
  void initState() {
    super.initState();
    _reverseGeocode();
  }

  void _setWgs(LatLng wgs, {bool recenter = false}) {
    setState(() => _wgs = wgs);
    if (recenter) {
      _mapCtrl.move(_display, 16);
    }
    _reverseGeocode();
  }

  Future<void> _reverseGeocode() async {
    final token = ++_geoToken;
    setState(() {
      _resolving = true;
      _locateError = null;
    });
    final result =
        await GeoService.reverseGeocode(_wgs.latitude, _wgs.longitude);
    if (!mounted || token != _geoToken) return;
    setState(() {
      _resolving = false;
      _address = result?.address ?? '';
    });
  }

  Future<void> _useCurrent() async {
    setState(() {
      _locating = true;
      _locateError = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locating = false;
          _locateError = '定位权限被拒绝，可手动点按地图选点';
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() => _locating = false);
      _setWgs(LatLng(pos.latitude, pos.longitude), recenter: true);
    } catch (e) {
      setState(() {
        _locating = false;
        _locateError = '定位失败：$e';
      });
    }
  }

  void _useSample() =>
      _setWgs(const LatLng(kSampleLat, kSampleLng), recenter: true);

  void _confirm() {
    Navigator.of(context).pop(PickedLocation(
      _wgs.latitude,
      _wgs.longitude,
      'map',
      address: _address,
    ));
  }

  String get _topText {
    if (_locateError != null) return _locateError!;
    if (_resolving) return '正在解析地址…';
    if (_address.isNotEmpty) return _address;
    return '${_wgs.latitude.toStringAsFixed(5)}, ${_wgs.longitude.toStringAsFixed(5)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _display,
              initialZoom: 16,
              onTap: (tapPosition, latLng) {
                // 地图点按返回的是 GCJ-02 下的视觉坐标，反算成 WGS-84 存储
                _setWgs(gcjToWgs(latLng.latitude, latLng.longitude));
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=7&x={x}&y={y}&z={z}',
                subdomains: const ['1', '2', '3', '4'],
                userAgentPackageName: 'com.lastcheck.lastcheck_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _display,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.danger,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 顶部地址提示
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  if (_resolving)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.place_rounded,
                        size: 16, color: AppColors.primaryDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _topText,
                      style: const TextStyle(
                          color: AppColors.textDark, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 底部操作
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _locating ? null : _useCurrent,
                        icon: _locating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location_rounded, size: 18),
                        label: const Text('当前位置'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _useSample,
                        icon: const Icon(Icons.place_rounded, size: 18),
                        label: const Text('示例位置'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _confirm,
                  child: const Text('确定选点'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

