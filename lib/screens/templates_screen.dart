import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/presets.dart';
import '../models/place.dart';
import '../theme.dart';
import 'location_picker_screen.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<ScenePreset> _presets = [];
  List<Map<String, dynamic>> _custom = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  AppServices get _svc => ServicesScope.of(context);

  void _load() {
    setState(() {
      _presets = sceneTypes;
      _custom = _svc.repo.getTemplates();
    });
  }

  Future<void> _onNew() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建清单'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '如：图书馆、学校、出差包',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final list = _svc.repo.getTemplates();
    list.add({'id': 't_${DateTime.now().millisecondsSinceEpoch}', 'name': name, 'items': <String>[]});
    _svc.repo.saveTemplates(list);
    _load();
    _toast('已创建「$name」，可先用到地点');
  }

  Future<void> _onUse({String? key, String? customId}) async {
    List<String> items;
    String label;
    if (customId != null) {
      final t = _custom.where((x) => x['id'] == customId).firstOrNull;
      if (t == null) return;
      items = ((t['items'] as List?) ?? []).cast<String>();
      label = (t['name'] as String?) ?? '自定义';
    } else {
      final p = _presets.where((x) => x.key == key).firstOrNull;
      if (p == null) return;
      items = p.items;
      label = p.label;
    }
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(title: '给「$label」选个位置'),
      ),
    );
    if (picked == null || !mounted) return;
    final place = _svc.places.add(Place(
          id: 'p_${DateTime.now().millisecondsSinceEpoch}',
          name: label,
          latitude: picked.latitude,
          longitude: picked.longitude,
          radius: 100,
          items: items,
        ));
    _svc.places.setCurrentPlaceId(place.id);
    _toast('已创建「$label」，清单已套用');
  }

  void _onDeleteCustom(String id) {
    _svc.repo.saveTemplates(_custom.where((x) => x['id'] != id).toList());
    _load();
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
      appBar: AppBar(
        title: const Text('常用清单'),
        actions: [
          IconButton(
            tooltip: '新建清单',
            onPressed: _onNew,
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryDark),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _SectionTitle('场景模板'),
          const SizedBox(height: 8),
          for (final p in _presets)
            _TemplateCard(
              name: p.label,
              items: p.items,
              onUse: () => _onUse(key: p.key),
            ),
          if (_custom.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _SectionTitle('我的清单'),
            const SizedBox(height: 8),
            for (final t in _custom)
              _TemplateCard(
                name: (t['name'] as String?) ?? '未命名',
                items: ((t['items'] as List?) ?? []).cast<String>(),
                custom: true,
                onUse: () => _onUse(customId: t['id'] as String),
                onDelete: () => _onDeleteCustom(t['id'] as String),
              ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final String name;
  final List<String> items;
  final VoidCallback onUse;
  final bool custom;
  final VoidCallback? onDelete;
  const _TemplateCard({
    required this.name,
    required this.items,
    required this.onUse,
    this.custom = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                custom ? Icons.bookmark_outline_rounded : Icons.style_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (custom && onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.textGrey, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in items)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primaryDark),
                  ),
                ),
              if (items.isEmpty)
                const Text('清单为空',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(120, 40),
              ),
              onPressed: onUse,
              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
              label: const Text('套用到地点'),
            ),
          ),
        ],
      ),
    );
  }
}
