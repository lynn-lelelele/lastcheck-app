import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 本地通知服务：系统级通知，App 被杀也能弹出。
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final ok = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      _initialized = ok == true;
      debugPrint('[LastCheck] notifications initialized: $_initialized');
    } catch (e) {
      debugPrint('[LastCheck] notification init failed: $e');
    }
  }

  /// Android 13+ 需要运行时通知权限。
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final ok = await android?.requestNotificationsPermission();
    return ok ?? true;
  }

  Future<bool> hasPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final ok = await android?.areNotificationsEnabled();
    return ok ?? true;
  }

  Future<void> showReminder(String placeName, String message) async {
    if (!_initialized) return;
    try {
      await _plugin.show(
        id: Random().nextInt(1000000),
        title: '出门清单 · $placeName',
        body: message,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'lastcheck_reminders',
            '出门提醒',
            channelDescription: '离开常去地点时提醒你检查携带清单',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: DarwinNotificationDetails(
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[LastCheck] showReminder failed: $e');
    }
  }
}

