import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../data/presets.dart';
import '../models/place.dart';
import '../theme.dart';
import 'location_picker_screen.dart';
import '../widgets/island_header.dart';
import '../widgets/name_sheet.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Place> _places = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  AppServices get _svc => ServicesScope.of(context);

  void _load() => setState(() => _places = _svc.places.list());

  Future<void> _onAdd() async {
    final labels = [for (final s in sceneTypes) s.label, '其他'];
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('添加常去地点',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            ),
            for (final label in labels)
              ListTile(
                leading: const Icon(Icons.place_rounded, color: AppColors.primary),
                title: Text(label),
                onTap: () => Navigator.pop(ctx, label),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    ScenePreset? preset;
    if (choice != '其他') {
      preset = sceneTypes.where((s) => s.label == choice).firstOrNull;
    }
    String name = choice;
    if (choice == '其他') {
      name = await _askCustomName() ?? '';
      if (name.isEmpty) return;
    }
    if (!mounted) return;
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(title: '给「$name」选个位置'),
      ),
    );
    if (picked == null || !mounted) return;

    final exists = _svc.places.list().any((p) => p.name == name);
    if (exists) {
      final confirm = await _confirmDuplicate(name);
      if (confirm != true) return;
    }
    final place = _svc.places.add(Place(
          id: 'p_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          address: picked.address,
          latitude: picked.latitude,
          longitude: picked.longitude,
          radius: 100,
          items: preset?.items ?? const [],
          sceneType: preset?.key,
        ));
    _svc.places.setCurrentPlaceId(place.id);
    _svc.geofence.sync(_svc.places.list());
    HapticFeedback.lightImpact();
    _load();
    _toast('已添加「$name」');
  }

  Future<String?> _askCustomName() {
    return showNameSheet(
      context,
      title: '地点名称',
      hint: '如：图书馆、学校、医院',
      confirm: '确定',
    );
  }

  Future<bool?> _confirmDuplicate(String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('已有同名地点'),
        content: Text('已存在「$name」，仍要再添加一个吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('仍要添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _editRadius(Place p) async {
    const options = ['50 米', '100 米', '200 米', '300 米', '500 米'];
    const radii = [50, 100, 200, 300, 500];
    final idx = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('提醒半径',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 8),
            for (var i = 0; i < options.length; i++)
              ListTile(
                title: Text(options[i]),
                trailing: p.radius == radii[i]
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, radii[i]),
              ),
          ],
        ),
      ),
    );
    if (idx == null) return;
    _svc.places.update(p.id, (x) => x.copyWith(radius: idx.toDouble()));
    _svc.geofence.sync(_svc.places.list());
    _load();
  }

  Future<void> _delete(Place p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除地点'),
        content: Text('删除「${p.name}」后，这里对应的清单也会一并移除。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      _svc.places.remove(p.id);
      _svc.geofence.sync(_svc.places.list());
      _load();
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(84),
        child: const IslandHeader(title: '常去地点'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAdd,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('添加地点'),
      ),
      body: _places.isEmpty
          ? const Center(
              child: Text('还没有地点，点右下角添加',
                  style: TextStyle(color: AppColors.textGrey)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                for (final p in _places)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PlaceCard(
                      place: p,
                      onRadius: () => _editRadius(p),
                      onDelete: () => _delete(p),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onRadius;
  final VoidCallback onDelete;
  const _PlaceCard({
    required this.place,
    required this.onRadius,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDeco.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              IconButton(
                tooltip: '删除',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.danger, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            place.address.isNotEmpty
                ? place.address
                : '${place.latitude.toStringAsFixed(5)}, ${place.longitude.toStringAsFixed(5)}',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _TagButton(
                icon: Icons.radar_rounded,
                text: '半径 ${place.radius.toInt()}m',
                onTap: onRadius,
              ),
              const Spacer(),
              if (place.items.isNotEmpty)
                Text(
                  '${place.items.length} 件物品',
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _TagButton({required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primaryDark),
            const SizedBox(width: 4),
            Text(text,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.primaryDark)),
          ],
        ),
      ),
    );
  }
}






