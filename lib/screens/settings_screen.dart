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
  int _geofenceCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPermission();
      _refreshNotif();
      _refreshGeofence();
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

  Future<void> _requestIgnoreBattery() async {
    final go = await showButlerDialog(
      context,
      title: '再帮您放行一下后台',
      content: '为了出门提醒不被系统杀掉，请到系统设置里允许 LastCheck 后台运行、自启动（国产手机必查）。',
      confirm: '去系统设置',
      cancel: '稍后再说',
    );
    if (go == true) {
      await Geolocator.openAppSettings();
    }
  }

  Future<void> _openHealthSheet() async {
    final locAlways =
        _permission == LocationPermission.always;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.all(22),
        decoration: AppDeco.island(radius: 28),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('权限体检',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              const SizedBox(height: 4),
              const Text('缺哪项点哪项，管家带您去补齐',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textGrey)),
              const SizedBox(height: 12),
              _HealthRow(
                icon: Icons.location_on_outlined,
                label: '定位（始终允许）',
                ok: locAlways,
                onFix: () {
                  Navigator.pop(ctx);
                  _onRequestAuth();
                },
              ),
              _HealthRow(
                icon: Icons.notifications_none_rounded,
                label: '通知（允许通知）',
                ok: _notifEnabled,
                onFix: () {
                  Navigator.pop(ctx);
                  _onRequestNotif();
                },
              ),
              _HealthRow(
                icon: Icons.battery_saver_outlined,
                label: '后台（允许运行/自启动）',
                ok: false,
                onFix: () {
                  Navigator.pop(ctx);
                  _requestIgnoreBattery();
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('关闭',
                    style: TextStyle(color: AppColors.textGrey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshGeofence() async {
    final n = await ServicesScope.of(context).geofence.getRegisteredCount();
    if (!mounted) return;
    setState(() => _geofenceCount = n);
  }

  Future<void> _testNotification() async {
    await ServicesScope.of(context).notifications.showReminder(
        '测试地点', '这是管家发的测试通知：能看到这条，说明通知通道是通的。');
    if (!mounted) return;
    _toast('已发送测试通知，请下拉通知栏查看');
  }

  Future<void> _resyncGeofence() async {
    final svc = ServicesScope.of(context);
    await svc.geofence.sync(svc.places.list());
    await _refreshGeofence();
    if (!mounted) return;
    _toast('围栏已重新同步');
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
            icon: Icons.health_and_safety_outlined,
            title: '权限体检',
            subtitle: '定位${_permission == LocationPermission.always ? "✓" : "✗"}  通知${_notifEnabled ? "✓" : "✗"}  后台去设置放行（点开逐项补齐）',
            onTap: _openHealthSheet,
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textGrey, size: 22),
          ),
          const SizedBox(height: 12),
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
            icon: Icons.campaign_outlined,
            title: '测试通知',
            subtitle: '立刻发一条系统通知，检验通知通道是否通畅',
            onTap: _testNotification,
            trailing: const Icon(Icons.notifications_active_rounded,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 12),
          _SettingCard(
            icon: Icons.radar_rounded,
            title: '围栏状态',
            subtitle: '已注册 $_geofenceCount 个地点的围栏（点击重新同步）',
            onTap: _resyncGeofence,
            trailing: const Icon(Icons.refresh_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 12),
          _SettingCard(
            icon: Icons.bolt_outlined,
            title: '耗电说明',
            subtitle: '本 App 用系统级围栏，不持续后台定位，耗电极低（约 1%/天）',
            trailing: const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(height: 12),
          _SettingCard(
            icon: Icons.battery_saver_outlined,
            title: '后台运行',
            subtitle: '请求系统忽略电池优化，围栏才不会被杀掉（点按跳系统设置）',
            trailing: OutlinedButton(
              onPressed: _requestIgnoreBattery,
              style: OutlinedButton.styleFrom(minimumSize: const Size(84, 38)),
              child: const Text('一键放行'),
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
  final VoidCallback? onTap;
  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
    ),
    );
  }
}












class _HealthRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool ok;
  final VoidCallback onFix;
  const _HealthRow({
    required this.icon,
    required this.label,
    required this.ok,
    required this.onFix,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: ok ? AppColors.success : AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 15, color: AppColors.textDark, fontWeight: FontWeight.w500),
            ),
          ),
          if (ok)
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 20)
          else
            OutlinedButton(
              onPressed: onFix,
              style: OutlinedButton.styleFrom(minimumSize: const Size(76, 36)),
              child: const Text('去补齐'),
            ),
        ],
      ),
    );
  }
}




