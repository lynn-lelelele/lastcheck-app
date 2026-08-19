import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../app_services.dart';
import '../theme.dart';
import '../widgets/butler_dialog.dart';
import '../widgets/island_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  LocationPermission _permission = LocationPermission.denied;
  bool _serviceEnabled = false;
  bool _notifEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPermission();
      _refreshNotif();
    });
  }

  Future<void> _refreshPermission() async {
    final permission = await Geolocator.checkPermission();
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    setState(() {
      _permission = permission;
      _serviceEnabled = enabled;
    });
  }

  bool get _authorized =>
      _permission == LocationPermission.always ||
      _permission == LocationPermission.whileInUse;

  Future<void> _refreshNotif() async {
    final ok = await ServicesScope.of(context).notifications.hasPermission();
    if (!mounted) return;
    setState(() => _notifEnabled = ok);
  }

  Future<void> _onRequestNotif() async {
    var ok = await ServicesScope.of(context).notifications.requestPermission();
    await _refreshNotif();
    if (!mounted) return;
    if (ok) {
      _toast('好的，谢谢您');
      return;
    }
    // 系统弹窗被跳过/已拒绝时，管家式引导去系统设置手动开启
    final go = await showButlerDialog(
      context,
      title: '还想再麻烦您一件事',
      content: '通知权限就像我递给您的小纸条：平时绝不打扰，只在您要出门时递一张清单。\n请到 系统设置 → 应用 → LastCheck → 通知，打开「允许通知」。',
      confirm: '去系统设置',
      cancel: '稍后再说',
    );
    if (go == true) {
      await Geolocator.openAppSettings();
      await _refreshNotif();
    }
  }

  Future<void> _onRequestAuth() async {
    final go = await showButlerDialog(
      context,
      title: '请允许我照顾您的出门小事',
      content: '为了能在您离开常去地点时及时提醒，我需要一直知道您的大概位置。\n请选择「始终允许」——我平时绝不打扰您，位置也只在本机用来判断围栏。',
    );
    if (!mounted || go != true) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    await _refreshPermission();
    if (!mounted) return;
    if (permission == LocationPermission.deniedForever) {
      _toast('定位被永久拒绝了，可到系统设置里重新开启');
    } else if (_authorized) {
      _toast('好的，谢谢您');
    } else {
      _toast('没关系，仍可手动核对清单');
    }
  }

  void _onDemoRemind() {
    AppEvents.demoRemind.value++;
    AppEvents.tabIndex.value = 0;
    _toast('正在演示「离开围栏提醒」');
  }

  Future<void> _onClearData() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空本地数据'),
        content: const Text('将删除所有地点与清单数据，此操作不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    ServicesScope.of(context).repo.clearAll();
    ServicesScope.of(context).geofence.clearAll();
    _toast('已清空');
  }

  Future<void> _onCopyRepo() async {
    await Clipboard.setData(
        const ClipboardData(text: 'https://github.com/lynn-lelelele/lastcheck'));
    if (mounted) _toast('仓库地址已复制');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authText = _authorized
        ? (_permission == LocationPermission.always ? '已授权（始终）' : '已授权')
        : '未授权';
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(84),
        child: const IslandHeader(title: '设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingCard(
            icon: Icons.location_on_outlined,
            title: '定位权限',
            subtitle: _serviceEnabled ? authText : '系统定位服务未开启',
            trailing: _authorized
                ? const Icon(Icons.check_circle_rounded,
                    color: AppColors.success)
                : OutlinedButton(
                    onPressed: _onRequestAuth,
                    style: OutlinedButton.styleFrom(minimumSize: const Size(84, 38)),
                    child: const Text('去授权'),
                  ),
          ),
          const SizedBox(height: 12),
          _SettingCard(
            icon: Icons.notifications_none_rounded,
            title: '通知权限',
            subtitle: _notifEnabled
                ? '已开启（离开围栏会弹通知）'
                : '未开启（需在系统设置打开「通知」，不是「后台弹窗」）',
            trailing: _notifEnabled
                ? const Icon(Icons.check_circle_rounded,
                    color: AppColors.success)
                : OutlinedButton(
                    onPressed: _onRequestNotif,
                    style: OutlinedButton.styleFrom(minimumSize: const Size(84, 38)),
                    child: const Text('去开启'),
                  ),
          ),
          const SizedBox(height: 12),
          _SettingCard(
            icon: Icons.notifications_active_outlined,
            title: '演示出门提醒',
            subtitle: '模拟一次「离开围栏」推送，看清单页效果',
            trailing: IconButton(
              onPressed: _onDemoRemind,
              icon: const Icon(Icons.play_circle_fill_rounded,
                  color: AppColors.primary, size: 30),
            ),
          ),
          const SizedBox(height: 12),
          _SettingCard(
            icon: Icons.link_rounded,
            title: '开源仓库',
            subtitle: 'github.com/lynn-lelelele/lastcheck',
            trailing: IconButton(
              onPressed: _onCopyRepo,
              icon: const Icon(Icons.copy_rounded,
                  color: AppColors.textGrey, size: 22),
            ),
          ),
          const SizedBox(height: 12),
          _SettingCard(
            icon: Icons.delete_sweep_outlined,
            title: '清空本地数据',
            subtitle: '删除所有地点与清单',
            trailing: IconButton(
              onPressed: _onClearData,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger, size: 22),
            ),
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'LastCheck · 出门别忘  v0.2.0',
              style: TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppDeco.card(radius: 18),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textGrey)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}








