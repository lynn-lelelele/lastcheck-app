import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../app_services.dart';
import '../models/place.dart';
import '../theme.dart';
import 'location_picker_screen.dart';
import '../widgets/butler_dialog.dart';
import '../widgets/name_sheet.dart';

/// 场景 → 默认物品（focus=random 时使用）。
const _sceneItems = <String, List<String>>{
  'home': ['钥匙', '手机', '钱包', '充电器', '雨伞'],
  'office': ['工卡', '电脑', '充电器', '耳机'],
  'gym': ['毛巾', '换洗衣物', '水杯', '耳机', '健身卡'],
  'other': ['手机', '钱包', '钥匙'],
};

const _focusItems = <String, List<String>>{
  'essentials': ['钥匙', '手机', '钱包', '工卡', '充电器', '雨伞'],
  'devices': ['手机', '充电器', '耳机', '电脑', '充电宝'],
};

class GuideScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const GuideScreen({super.key, required this.onFinished});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  int _step = -1; // -1 welcome, 0..2 questions, 3 done
  final _answers = <String>[];
  String _summary = '';

  static const _questions = [
    (
      title: '你最常从哪出门？',
      options: [('home', '家'), ('office', '公司'), ('gym', '健身房'), ('other', '其他')],
    ),
    (
      title: '出门最怕忘带什么？',
      options: [
        ('essentials', '钥匙、证件这类必需品'),
        ('devices', '充电器、耳机这类电子设备'),
        ('random', '没准，什么都可能忘'),
      ],
    ),
    (
      title: '要不要开启自动提醒？',
      options: [
        ('on', '开启：离开常去地点时自动提醒（推荐）'),
        ('off', '暂不开启'),
      ],
    ),
  ];

  void _start() {
    setState(() => _step = 0);
  }

  Future<void> _pick(int optionIndex) async {
    HapticFeedback.selectionClick();
    final (key, label) = _questions[_step].options[optionIndex];
    final answers = [..._answers, key];

    if (_step == 0) {
      // 第 1 题：创建地点
      String name;
      if (key == 'other') {
        name = await _askCustomName() ?? '其他';
        if (name.isEmpty) name = '其他';
      } else {
        name = label;
      }
      final ok = await _createPlace(name, key, answers);
      if (!ok) return; // 用户取消选点
    } else if (_step == 1) {
      // 第 2 题：设置清单物品
      final scene = answers.first;
      final items = key == 'random'
          ? (_sceneItems[scene] ?? const ['手机', '钱包', '钥匙'])
          : (_focusItems[key] ?? const []);
      _applyItemsToLastPlace(items);
    } else {
      // 第 3 题：开启自动提醒 → 请求定位权限
      if (key == 'on') {
        _requestLocationPermission();
      }
      _buildSummary(answers);
      setState(() {
        _step = 3;
        _answers..clear()..addAll(answers);
      });
      return;
    }

    setState(() {
      _answers..clear()..addAll(answers);
      _step = _step + 1;
    });
  }

  Future<String?> _askCustomName() {
    return showNameSheet(
      context,
      title: '地点名称',
      hint: '如：图书馆、学校、医院',
      confirm: '确定',
    );
  }

  Future<bool> _createPlace(String name, String sceneKey, List<String> answers) async {
    final services = ServicesScope.of(context);
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(title: '给「$name」选个位置'),
      ),
    );
    if (picked == null) return false; // 用户取消
    final exists = services.places.list().any((p) => p.name == name);
    if (!exists) {
      final place = services.places.add(Place(
            id: 'p_${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            address: picked.address,
            latitude: picked.latitude,
            longitude: picked.longitude,
            radius: 100,
            sceneType: sceneKey,
          ));
      services.places.setCurrentPlaceId(place.id);
    }
    return true;
  }

  void _applyItemsToLastPlace(List<String> items) {
    final services = ServicesScope.of(context);
    final places = services.places.list();
    if (places.isEmpty) return;
    final last = places.last;
    services.places.update(last.id, (p) => p.copyWith(items: items, checkedMap: {}));
  }

  Future<void> _requestLocationPermission() async {
    // 管家式引导：先讲清逻辑，再请用户选「始终允许」
    final go = await showButlerDialog(
      context,
      title: '请允许我照顾您的出门小事',
      content: '为了能在您离开家/公司时及时提醒带齐东西，我需要一直知道您的大概位置。\n请选择「始终允许」——我平时绝不打扰您，位置也只在本机用来判断围栏。',
    );
    if (!mounted) return;
    if (go != true) {
      _toast('没关系，您随时可以在「设置」页开启定位');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    // 后台定位：Android 10+ 围栏需要「始终允许」
    if (permission == LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
    }
    // 通知权限：Android 13+ 需要运行时授权
    if (!mounted) return;
    final notifOk =
        await ServicesScope.of(context).notifications.requestPermission();
    if (!mounted) return;
    if (!notifOk) {
      final goNotif = await showButlerDialog(
        context,
        title: '还想再麻烦您一件事',
        content: '通知权限就像我递给您的小纸条：平时绝不打扰，只在您要出门时递一张清单。\n请到 系统设置 → 应用 → LastCheck → 通知，打开「允许通知」。',
        confirm: '去系统设置',
        cancel: '稍后再说',
      );
      if (goNotif == true) {
        await Geolocator.openAppSettings();
      }
      if (!mounted) return;
    }
    if (permission == LocationPermission.deniedForever) {
      _toast('定位被拒绝了，可以在「设置」页重新开启');
    } else if (permission == LocationPermission.denied) {
      _toast('暂时没开定位也没关系，出门前自己核对一下清单就好');
    } else {
      _toast('都安排好了：您只管出门，我来提醒');
    }
  }

  void _buildSummary(List<String> answers) {
    final services = ServicesScope.of(context);
    final places = services.places.list();
    if (places.isNotEmpty) {
      final place = places.last;
      _summary = '已为你准备「${place.name}」的出门清单（${place.items.length} 件物品），离开时会自动提醒你。';
    } else {
      _summary = '已记录你的偏好，可稍后在「地点」页补充。';
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _finish() {
    ServicesScope.of(context).repo.setGuideSeen();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: _step < 0
              ? _Welcome(onStart: _start)
              : _step < 3
                  ? _QuestionView(
                      key: ValueKey(_step),
                      title: _questions[_step].title,
                      options: _questions[_step].options,
                      progress: _step + 1,
                      total: _questions.length,
                      onPick: _pick,
                    )
                  : _Done(summary: _summary, onFinish: _finish),
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  final VoidCallback onStart;
  const _Welcome({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.verified_user_rounded, size: 72, color: AppColors.primary),
          const SizedBox(height: 24),
          const Text(
            'LastCheck\n出门别忘',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '您好，我是您的出门管家。\n您只管放心出门，离开常去地点时，我会提前把「该带的东西」递到您面前。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.textGrey, height: 1.6),
          ),
          const SizedBox(height: 40),
          FilledButton(onPressed: onStart, child: const Text('开始使用')),
        ],
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  final String title;
  final List<(String, String)> options;
  final int progress;
  final int total;
  final ValueChanged<int> onPick;
  const _QuestionView({
    super.key,
    required this.title,
    required this.options,
    required this.progress,
    required this.total,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: progress / total,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
            backgroundColor: AppColors.primarySoft,
            color: AppColors.primary,
          ),
          const Spacer(),
          Text(
            '$progress / $total',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 28),
          ...List.generate(options.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Material(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onPick(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primarySoft),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            options[i].$2,
                            style: const TextStyle(
                                fontSize: 15, color: AppColors.textDark),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textGrey),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _Done extends StatelessWidget {
  final String summary;
  final VoidCallback onFinish;
  const _Done({required this.summary, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
            child: const Icon(Icons.check_circle_rounded,
                size: 80, color: AppColors.success),
          ),
          const SizedBox(height: 24),
          Text(
            summary,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              color: AppColors.textDark,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          FilledButton(onPressed: onFinish, child: const Text('开始使用')),
        ],
      ),
    );
  }
}







