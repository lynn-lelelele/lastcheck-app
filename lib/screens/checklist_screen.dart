import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../models/place.dart';
import '../services/message_service.dart';
import '../widgets/island_header.dart';
import '../theme.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Place> _places = [];
  String _currentPlaceId = '';
  Place? _current;
  List<String> _items = [];
  Map<int, bool> _checkedMap = {};
  bool _showLeaveCard = false;
  bool _editMode = false;
  bool _celebration = false;
  final _newItemCtrl = TextEditingController();
  int _notifNonce = 0;
  String _notifContent = '';

  @override
  void initState() {
    super.initState();
    AppEvents.demoRemind.addListener(_onDemoRemind);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    AppEvents.demoRemind.removeListener(_onDemoRemind);
    _newItemCtrl.dispose();
    super.dispose();
  }

  void _onDemoRemind() {
    if (mounted) _manualLeave();
  }

  AppServices get _svc => ServicesScope.of(context);

  void _load() {
    final places = _svc.places.list();
    if (places.isEmpty) {
      setState(() {
        _places = [];
        _current = null;
        _items = [];
        _checkedMap = {};
        _showLeaveCard = false;
        _editMode = false;
      });
      return;
    }
    var id = _svc.places.getCurrentPlaceId();
    if (!places.any((p) => p.id == id)) {
      id = places.first.id;
      _svc.places.setCurrentPlaceId(id);
    }
    final current = _svc.places.findById(id);
    setState(() {
      _places = places;
      _currentPlaceId = id;
      _current = current;
      _items = current?.items ?? [];
      _checkedMap = current?.checkedMap ?? {};
      _showLeaveCard = false;
      _editMode = false;
    });
  }

  void _switchPlace(String id) {
    _svc.places.setCurrentPlaceId(id);
    _load();
  }

  void _toggleItem(int index) {
    HapticFeedback.selectionClick();
    final next = Map<int, bool>.from(_checkedMap);
    next[index] = !(next[index] ?? false);
    setState(() => _checkedMap = next);
    _svc.checklist.setCheckedMap(_currentPlaceId, next);
    _refreshLeaveStatus();
    final allChecked = List.generate(_items.length, (i) => next[i] ?? false).every((v) => v);
      if (next[index] == true && allChecked) {
      _celebrate();
    }
  }

  void _checkAll() {
    HapticFeedback.heavyImpact();
    final next = <int, bool>{for (var i = 0; i < _items.length; i++) i: true};
    setState(() => _checkedMap = next);
    _svc.checklist.setCheckedMap(_currentPlaceId, next);
    _refreshLeaveStatus();
    _celebrate();
  }

  void _celebrate() {
    setState(() => _celebration = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _celebration = false);
    });
  }

  List<String> get _pending {
    return [
      for (var i = 0; i < _items.length; i++)
        if (!(_checkedMap[i] ?? false)) _items[i],
    ];
  }

  void _manualLeave() {
    HapticFeedback.heavyImpact();
    if (_current == null) return;
    setState(() {
      _showLeaveCard = true;
      _notifNonce++;
    });
    final content = buildLeaveMessage(_current!, _pending);
    setState(() => _notifContent = content);
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _notifNonce = 0);
    });
    _refreshLeaveStatus();
  }

  void _refreshLeaveStatus() {
    if (!_showLeaveCard) return;
    setState(() {});
  }

  void _addItem() {
    final name = _newItemCtrl.text.trim();
    if (name.isEmpty) return;
    final items = _svc.checklist.addItem(_currentPlaceId, name);
    if (items != null) {
      setState(() {
        _items = items;
        _newItemCtrl.clear();
      });
    }
  }

  void _removeItem(int index) {
    final r = _svc.checklist.removeItem(_currentPlaceId, index);
    if (r != null) {
      setState(() {
        _items = r.items;
        _checkedMap = r.checkedMap;
      });
    }
  }

  void _switchTab(int i) => AppEvents.tabIndex.value = i;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(84),
        child: IslandHeader(
          title: '出门别忘',
          actions: [
            if (_places.isNotEmpty)
              IconButton(
                tooltip: _editMode ? '完成' : '编辑',
                onPressed: () => setState(() => _editMode = !_editMode),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _editMode ? Icons.check_rounded : Icons.edit_outlined,
                    key: ValueKey(_editMode),
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
          _places.isEmpty ? _EmptyState(onGoTemplates: () => _switchTab(2)) : _buildList(),
          if (_notifNonce > 0) _MockNotification(content: _notifContent),
          if (_celebration) const _CelebrationOverlay(),
        ],
      ),
    );
  }

  Widget _buildList() {
    final checkedCount = List.generate(_items.length, (i) => _checkedMap[i] ?? false).where((v) => v).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // 地点切换
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _places.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final p = _places[i];
              final selected = p.id == _currentPlaceId;
              return GestureDetector(
                onTap: () => _switchPlace(p.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.primarySoft,
                    ),
                  ),
                  child: Text(
                    p.name,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textDark,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // 进度卡片
        _ProgressCard(checked: checkedCount, total: _items.length),
        const SizedBox(height: 16),
        // 清单项
        ...List.generate(_items.length, (i) {
          return _ItemTile(
            key: ValueKey('item_$i'),
            index: i,
            name: _items[i],
            checked: _checkedMap[i] ?? false,
            editMode: _editMode,
            onToggle: () => _toggleItem(i),
            onRemove: () => _removeItem(i),
          );
        }),
        // 编辑模式：添加项
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: _editMode
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newItemCtrl,
                          decoration: const InputDecoration(
                            hintText: '添加要带的东西…',
                            filled: true,
                            fillColor: AppColors.card,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(14)),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _addItem(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(52, 48),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: _addItem,
                        child: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 20),
        // 操作按钮
        if (!_editMode) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _items.isEmpty ? null : _checkAll,
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('全部确认已带'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _items.isEmpty ? null : _manualLeave,
                  icon: const Icon(Icons.directions_walk_rounded, size: 20),
                  label: const Text('我出门了'),
                ),
              ),
            ],
          ),
          // 出门提醒卡片
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: _showLeaveCard ? _LeaveCard(pending: _pending, onClose: () {
              setState(() => _showLeaveCard = false);
            }) : const SizedBox.shrink(),
          ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

}

class _EmptyState extends StatelessWidget {
  final VoidCallback onGoTemplates;
  const _EmptyState({required this.onGoTemplates});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 64, color: AppColors.textGrey),
            const SizedBox(height: 16),
            const Text(
              '还没有场所',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              '添加一个常去地点，或从「常用」清单一键创建。',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onGoTemplates,
              icon: const Icon(Icons.style_rounded),
              label: const Text('去常用清单看看'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int checked;
  final int total;
  const _ProgressCard({required this.checked, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : checked / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDeco.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('已带',
                  style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
              Text(
                '$checked / $total',
                style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: AppColors.primarySoft,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final int index;
  final String name;
  final bool checked;
  final bool editMode;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  const _ItemTile({
    super.key,
    required this.index,
    required this.name,
    required this.checked,
    required this.editMode,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: editMode ? null : onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: checked ? AppColors.primarySoft : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                // 勾选圆
                TweenAnimationBuilder<double>(
                  tween: Tween(end: checked ? 1.0 : 0.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  builder: (_, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: checked ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: checked ? AppColors.primary : AppColors.textGrey,
                        width: 1.6,
                      ),
                    ),
                    child: checked
                        ? const Icon(Icons.check_rounded,
                            size: 18, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 16,
                      color: checked ? AppColors.textGrey : AppColors.textDark,
                      decoration: checked ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textGrey,
                    ),
                    child: Text(name),
                  ),
                ),
                if (editMode)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.remove_circle_outline_rounded,
                        color: AppColors.danger),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final List<String> pending;
  final VoidCallback onClose;
  const _LeaveCard({required this.pending, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final allOk = pending.isEmpty;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: allOk ? const Color(0xFFEAF3EA) : const Color(0xFFFFF3E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allOk ? AppColors.success : AppColors.primary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allOk ? Icons.verified_rounded : Icons.notification_important_rounded,
                color: allOk ? AppColors.success : AppColors.primaryDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  allOk ? '全部确认已带，可以安心出门' : '还有未确认：${pending.join('、')}',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close_rounded, color: AppColors.textGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 顶部滑入的模拟通知横幅（Phase 2 会替换为系统本地通知）。
class _MockNotification extends StatelessWidget {
  final String content;
  const _MockNotification({required this.content});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      left: 12,
      right: 12,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutBack,
        builder: (_, v, child) => Transform.translate(
          offset: Offset(0, -48 * (1 - v)),
          child: Opacity(opacity: v, child: child),
        ),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(14),
          color: AppColors.textDark,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: Color(0xFFFFD9A0)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    content,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 全部确认已带时的庆祝浮层。
class _CelebrationOverlay extends StatelessWidget {
  const _CelebrationOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.4, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: const Text('全部确认已带！',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success)),
        ),
      ),
    );
  }
}





