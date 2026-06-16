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

class TaskReminderService {
  TaskReminderService._();
  static final TaskReminderService instance = TaskReminderService._();

  static const _keyHour = 'task_reminder_hour';
  static const _keyMinute = 'task_reminder_minute';
  static const _keyEnabled = 'task_reminder_enabled';
  static const _keyLastShown = 'task_reminder_last_shown';
  static const notificationId = 1001;
  static const channelId = 'daily_task_channel';

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _timezoneReady = false;

  Future<void> _configureLocalTimeZone() async {
    if (_timezoneReady) return;
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    }
    _timezoneReady = true;
  }

  Future<AndroidFlutterLocalNotificationsPlugin?> _androidPlugin() async {
    return _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  }

  Future<void> _setupAndroidChannel() async {
    final androidPlugin = await _androidPlugin();
    if (androidPlugin == null) return;
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        '每日任务提醒',
        description: '汇总待更换与待贴标签任务',
        importance: Importance.high,
      ),
    );
    await androidPlugin.requestNotificationsPermission();
    await androidPlugin.requestExactAlarmsPermission();
  }

  Future<void> init() async {
    if (_initialized) return;
    await _configureLocalTimeZone();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (_) {},
    );
    await _setupAndroidChannel();
    _initialized = true;
    await scheduleDailyNotification();
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
      await _notifications.cancel(notificationId);
      return;
    }
    await _safeSchedule();
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
    await _safeSchedule();
  }

  Future<void> _safeSchedule() async {
    try {
      await scheduleDailyNotification();
    } catch (_) {
      // 偏好已保存，应用内弹窗仍可用
    }
  }

  String _todayKey(DateTime now) =>
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  Future<bool> shouldShowInAppDialog() async {
    if (!await isEnabled()) return false;
    final now = DateTime.now();
    final time = await getReminderTime();
    final scheduled = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (now.isBefore(scheduled)) return false;
    final prefs = await _prefs();
    return prefs.getString(_keyLastShown) != _todayKey(now);
  }

  Future<void> markShownToday() async {
    final prefs = await _prefs();
    await prefs.setString(_keyLastShown, _todayKey(DateTime.now()));
  }

  NotificationDetails get _notificationDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          '每日任务提醒',
          channelDescription: '汇总待更换与待贴标签任务',
          importance: Importance.max,
          priority: Priority.high,
          visibility: NotificationVisibility.public,
        ),
        iOS: DarwinNotificationDetails(),
      );

  Future<void> scheduleDailyNotification() async {
    if (!_initialized) {
      await init();
      return;
    }
    if (!await isEnabled()) return;

    await _configureLocalTimeZone();
    await _setupAndroidChannel();

    final time = await getReminderTime();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _notifications.cancel(notificationId);
    try {
      await _notifications.zonedSchedule(
        notificationId,
        '今日任务汇总',
        '请查看待更换与待贴标签任务',
        scheduled,
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      await _notifications.zonedSchedule(
        notificationId,
        '今日任务汇总',
        '请查看待更换与待贴标签任务',
        scheduled,
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> showDailySummaryNotification({required int replacePending, required int labelPending}) async {
    if (!_initialized) await init();
    if (!await isEnabled()) return;
    final total = replacePending + labelPending;
    final body = total > 0 ? '待更换 $replacePending 项，待贴标签 $labelPending 项' : '当前暂无待处理任务';
    await _notifications.show(
      notificationId + 1,
      '今日任务汇总',
      body,
      _notificationDetails,
    );
  }
}
