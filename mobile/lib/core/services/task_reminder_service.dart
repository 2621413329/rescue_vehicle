import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (_) {},
    );
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
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
    if (value) {
      await scheduleDailyNotification();
    } else {
      await _notifications.cancel(notificationId);
    }
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
    await scheduleDailyNotification();
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

  Future<void> scheduleDailyNotification() async {
    if (!_initialized) await init();
    if (!await isEnabled()) return;

    final time = await getReminderTime();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_task_channel',
      '每日任务提醒',
      channelDescription: '汇总待更换与待贴标签任务',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.zonedSchedule(
      notificationId,
      '今日任务汇总',
      '请查看待更换与待贴标签任务',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showInstantNotification({required String title, required String body}) async {
    if (!_initialized) await init();
    const androidDetails = AndroidNotificationDetails(
      'daily_task_channel',
      '每日任务提醒',
      channelDescription: '汇总待更换与待贴标签任务',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    await _notifications.show(
      notificationId + 1,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
}
