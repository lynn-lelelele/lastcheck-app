import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// 悬浮岛式「编辑物品」弹窗：增删清单里的物品。
/// 返回编辑后的物品列表；取消返回 null。
Future<List<String>?> showItemEditor(
  BuildContext context, {
  required String title,
  required List<String> initialItems,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ItemEditorSheet(title: title, initialItems: initialItems),
  );
}

class _ItemEditorSheet extends StatefulWidget {
  final String title;
  final List<String> initialItems;
  const _ItemEditorSheet({required this.title, required this.initialItems});

  @override
  State<_ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends State<_ItemEditorSheet> {
  late final List<String> _items = List.of(widget.initialItems);
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add() {
    final v = _ctrl.text.trim();
    if (v.isEmpty) return;
    setState(() {
      _items.add(v);
      _ctrl.clear();
    });
    HapticFeedback.selectionClick();
  }

  void _remove(int index) {
    setState(() => _items.removeAt(index));
    HapticFeedback.lightImpact();
  }

  void _done() {
    Navigator.of(context).pop(List.of(_items));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          padding: const EdgeInsets.all(22),
          decoration: AppDeco.island(radius: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '编辑「${widget.title}」',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '增减要带的物品，套用时清单会跟着变',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
              const SizedBox(height: 16),
              // 物品列表
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        _ItemChip(
                          label: _items[i],
                          onRemove: () => _remove(i),
                        ),
                      if (_items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '还没有物品，在下面添加',
                            style:
                                TextStyle(fontSize: 13, color: AppColors.textGrey),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 添加行
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onSubmitted: (_) => _add(),
                      decoration: InputDecoration(
                        hintText: '添加物品…',
                        filled: true,
                        fillColor: AppColors.primarySoft.withValues(alpha: 0.5),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(52, 50),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: _add,
                    child: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton(onPressed: _done, child: const Text('完成')),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消',
                    style: TextStyle(color: AppColors.textGrey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ItemChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 4, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close_rounded,
                  size: 16, color: AppColors.textGrey),
            ),
          ),
        ],
      ),
    );
  }
}
