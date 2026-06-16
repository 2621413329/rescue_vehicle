import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

final taskReminderServiceProvider = Provider<TaskReminderService>((ref) {
  return TaskReminderService.instance;
});

/// 系统级本地通知：每日定时 + 立即推送（非 App 内 Dialog）。
class TaskReminderService {
  TaskReminderService._();
  static final TaskReminderService instance = TaskReminderService._();

  static const _keyHour = 'task_reminder_hour';
  static const _keyMinute = 'task_reminder_minute';
  static const _keyEnabled = 'task_reminder_enabled';
  static const _keyLastNotified = 'task_reminder_last_notified';
  static const scheduledNotificationId = 1001;
  static const summaryNotificationId = 1002;
  static const testNotificationId = 1999;
  static const channelId = 'daily_task_channel';
  static const channelName = '每日任务提醒';
  static const channelDesc = '汇总待更换与待贴标签任务';
  static const _androidNotificationIcon = '@drawable/ic_notification';

  static const scheduledTitle = '今日任务汇总';
  static const scheduledBody = '打开救备通，查看待更换与待贴标签任务';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  AndroidFlutterLocalNotificationsPlugin? _androidPlugin() =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<void> _configureLocalTimeZone() async {
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    }
  }

  NotificationDetails get _notificationDetails => NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          icon: _androidNotificationIcon,
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          importance: Importance.max,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  Future<void> initialize() async {
    if (_initialized) return;
    await _configureLocalTimeZone();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings(_androidNotificationIcon),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (_) {},
    );
    final android = _androidPlugin();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );
    _initialized = true;
    await scheduleFromPreferences();
  }

  /// 申请通知与精确闹钟权限（失败不抛错）。
  Future<void> requestPermission() async {
    try {
      if (!_initialized) await initialize();
      final android = _androidPlugin();
      await android?.requestNotificationsPermission();
      try {
        await android?.requestExactAlarmsPermission();
      } catch (_) {}
    } catch (_) {}
  }

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<bool> isEnabled() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyEnabled) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyEnabled, value);
    if (!value) {
      await _cancelScheduled();
      return;
    }
    await scheduleFromPreferences();
  }

  Future<TimeOfDay> getReminderTime() async {
    final prefs = await _prefs();
    return TimeOfDay(
      hour: prefs.getInt(_keyHour) ?? 10,
      minute: prefs.getInt(_keyMinute) ?? 0,
    );
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    final prefs = await _prefs();
    await prefs.setInt(_keyHour, time.hour);
    await prefs.setInt(_keyMinute, time.minute);
    await scheduleFromPreferences();
  }

  /// 根据偏好重新注册每日定时系统通知。
  Future<void> scheduleFromPreferences() async {
    if (!await isEnabled()) return;
    try {
      if (!_initialized) await initialize();
      if (!_initialized) return;

      await _configureLocalTimeZone();
      final time = await getReminderTime();
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.cancel(scheduledNotificationId);
      try {
        await _plugin.zonedSchedule(
          scheduledNotificationId,
          scheduledTitle,
          scheduledBody,
          scheduled,
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        await _plugin.zonedSchedule(
          scheduledNotificationId,
          scheduledTitle,
          scheduledBody,
          scheduled,
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (_) {}
  }

  Future<void> _cancelScheduled() async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(scheduledNotificationId);
      await _plugin.cancel(summaryNotificationId);
    } catch (_) {}
  }

  String _todayKey(DateTime now) =>
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  /// App 回到前台后，若已过提醒时间且今日尚未推送汇总，则补发系统通知。
  Future<bool> shouldFireSupplementalNotification() async {
    if (!await isEnabled()) return false;
    final now = DateTime.now();
    final time = await getReminderTime();
    final scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (now.isBefore(scheduled)) return false;
    final prefs = await _prefs();
    return prefs.getString(_keyLastNotified) != _todayKey(now);
  }

  Future<void> markNotifiedToday() async {
    final prefs = await _prefs();
    await prefs.setString(_keyLastNotified, _todayKey(DateTime.now()));
  }

  /// 立即弹出测试通知（验证通道是否正常）。
  Future<void> showTestNotification() async {
    await initialize();
    await requestPermission();
    await _plugin.show(
      testNotificationId,
      '提醒测试',
      '若能看到这条通知，说明推送通道已正常工作',
      _notificationDetails,
    );
  }

  /// 立即弹出带待办数量的系统通知（App 可关闭时由 zonedSchedule 负责固定文案）。
  Future<void> showDailySummaryNotification({
    required int replacePending,
    required int labelPending,
  }) async {
    if (!await isEnabled()) return;
    final pending = replacePending + labelPending;
    if (pending <= 0) {
      await markNotifiedToday();
      return;
    }
    try {
      if (!_initialized) await initialize();
      if (!_initialized) return;
      await requestPermission();
      await _plugin.show(
        summaryNotificationId,
        scheduledTitle,
        '待更换 $replacePending 项，待贴标签 $labelPending 项',
        _notificationDetails,
      );
      await markNotifiedToday();
    } catch (_) {}
  }
}
