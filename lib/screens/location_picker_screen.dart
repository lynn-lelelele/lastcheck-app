import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/geo_service.dart';
import '../theme.dart';

/// 位置选择结果。
class PickedLocation {
  final double latitude;
  final double longitude;
  final String source; // current / sample / map
  final String address;
  const PickedLocation(this.latitude, this.longitude, this.source,
      {this.address = ''});
}

/// 长沙示例坐标（小程序版演示位置）。
const kSampleLat = 28.228209;
const kSampleLng = 112.938814;

/// 全屏地图选点：点按地图放置标记，或用当前位置 / 示例位置。
/// 选点后自动反查地址，显示在地图顶部。
class LocationPickerScreen extends StatefulWidget {
  final String title;
  const LocationPickerScreen({super.key, this.title = '选择位置'});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng _point = const LatLng(kSampleLat, kSampleLng);
  bool _locating = false;
  String? _locateError;
  String _address = '';
  bool _resolving = false;
  int _geoToken = 0;

  @override
  void initState() {
    super.initState();
    _reverseGeocode();
  }

  Future<void> _reverseGeocode() async {
    final token = ++_geoToken;
    setState(() {
      _resolving = true;
      _locateError = null;
    });
    final result = await GeoService.reverseGeocode(
        _point.latitude, _point.longitude);
    if (!mounted || token != _geoToken) return;
    setState(() {
      _resolving = false;
      if (result != null) {
        _address = result.address;
      } else {
        _address = '';
      }
    });
  }

  void _setPoint(LatLng p) {
    setState(() => _point = p);
    _reverseGeocode();
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
      _setPoint(LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      setState(() {
        _locating = false;
        _locateError = '定位失败：$e';
      });
    }
  }

  void _useSample() => _setPoint(const LatLng(kSampleLat, kSampleLng));

  void _confirm() {
    Navigator.of(context).pop(PickedLocation(
      _point.latitude,
      _point.longitude,
      'map',
      address: _address,
    ));
  }

  String get _topText {
    if (_locateError != null) return _locateError!;
    if (_resolving) return '正在解析地址…';
    if (_address.isNotEmpty) return _address;
    return '${_point.latitude.toStringAsFixed(5)}, ${_point.longitude.toStringAsFixed(5)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _point,
              initialZoom: 16,
              onTap: (tapPosition, latLng) => _setPoint(latLng),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.lastcheck.lastcheck_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _point,
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
