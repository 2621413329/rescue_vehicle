import 'package:flutter/foundation.dart';
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

enum NotificationActionResult { success, initFailed, permissionDenied, failed }

@pragma('vm:entry-point')
void _onNotificationTap(NotificationResponse response) {}

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

  static const _androidIcon = 'ic_notification';

  static const scheduledTitle = '今日任务汇总';
  static const scheduledBody = '打开救备通，查看待更换与待贴标签任务';

  FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _timezoneReady = false;
  String? _activeIcon;
  Future<void>? _initFuture;
  String? _lastInitError;

  String? get lastInitError => _lastInitError;
  bool get isInitialized => _initialized;

  AndroidFlutterLocalNotificationsPlugin? _androidPlugin() =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  void _resetPluginState() {
    _plugin = FlutterLocalNotificationsPlugin();
    _initialized = false;
    _activeIcon = null;
    _initFuture = null;
  }

  Future<void> _configureLocalTimeZone() async {
    if (_timezoneReady) return;
    try {
      tz_data.initializeTimeZones();
      try {
        final name = await FlutterTimezone.getLocalTimezone().timeout(const Duration(seconds: 10));
        tz.setLocalLocation(tz.getLocation(_normalizeTimezone(name)));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
      }
      _timezoneReady = true;
    } catch (e) {
      _lastInitError = '时区配置失败: $e';
    }
  }

  String _normalizeTimezone(String name) {
    const aliases = {
      'China Standard Time': 'Asia/Shanghai',
      'CST': 'Asia/Shanghai',
      'Asia/Chongqing': 'Asia/Shanghai',
      'Asia/Harbin': 'Asia/Shanghai',
    };
    return aliases[name] ?? name;
  }

  NotificationDetails get _notificationDetails => NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          icon: _activeIcon ?? _androidIcon,
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

  Future<void> initialize({bool force = false}) async {
    if (_initialized && !force) return;
    if (force) _resetPluginState();
    try {
      await (_initFuture ??= _initializeImpl());
    } catch (e) {
      _initFuture = null;
      _lastInitError = '$e';
      if (kDebugMode) {
        debugPrint('[TaskReminderService] initialize failed: $e');
      }
    }
  }

  Future<void> _initializeImpl() async {
    if (_initialized) return;
    _lastInitError = null;

    final candidate = FlutterLocalNotificationsPlugin();
    try {
      final ok = await candidate.initialize(
        InitializationSettings(
          android: AndroidInitializationSettings(_androidIcon),
          iOS: const DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
      if (ok != true) {
        throw Exception('initialize returned false');
      }
      _plugin = candidate;
      _activeIcon = _androidIcon;
      _initialized = true;
    } catch (e) {
      throw Exception('通知插件初始化失败: $e');
    }

    try {
      await _androidPlugin()?.createNotificationChannel(
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
    } catch (e) {
      _lastInitError = '通知渠道创建失败（不影响测试通知）: $e';
    }
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await initialize();
  }

  Future<bool> _notificationsEnabled() async {
    final android = _androidPlugin();
    if (android == null) return true;
    try {
      return await android.areNotificationsEnabled() ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> requestNotificationPermission() async {
    try {
      await _ensureInitialized();
      if (!_initialized) return false;
      final android = _androidPlugin();
      if (android == null) return true;

      final enabled = await android.areNotificationsEnabled();
      if (enabled == true) return true;

      final granted = await android.requestNotificationsPermission();
      if (granted == true) return true;
      return await _notificationsEnabled();
    } catch (_) {
      return await _notificationsEnabled();
    }
  }

  Future<void> _requestExactAlarmPermissionIfNeeded() async {
    try {
      final android = _androidPlugin();
      if (android == null) return;
      final canExact = await android.canScheduleExactNotifications();
      if (canExact == true) return;
      await android.requestExactAlarmsPermission().timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<AndroidScheduleMode> _preferredScheduleMode() async {
    try {
      final android = _androidPlugin();
      final canExact = await android?.canScheduleExactNotifications();
      if (canExact == true) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (_) {}
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> requestPermission() async {
    await requestNotificationPermission();
    await _requestExactAlarmPermissionIfNeeded();
  }

  /// 进入 App 后弹出系统通知权限请求（Android 13+）。
  Future<void> requestNotificationPermissionOnLaunch() async {
    try {
      await initialize();
      if (!_initialized) return;

      final android = _androidPlugin();
      if (android == null) return;

      final enabled = await android.areNotificationsEnabled();
      if (enabled == true) return;

      await android.requestNotificationsPermission();
    } catch (_) {}
  }

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<bool> isEnabled() async {
    final prefs = await _prefs();
    return prefs.getBool(_keyEnabled) ?? true;
  }

  Future<bool> setEnabled(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_keyEnabled, value);
    if (!value) {
      await _cancelScheduled();
      return true;
    }
    await requestPermission();
    return scheduleFromPreferences();
  }

  Future<TimeOfDay> getReminderTime() async {
    final prefs = await _prefs();
    return TimeOfDay(
      hour: prefs.getInt(_keyHour) ?? 10,
      minute: prefs.getInt(_keyMinute) ?? 0,
    );
  }

  Future<bool> setReminderTime(TimeOfDay time) async {
    final prefs = await _prefs();
    await prefs.setInt(_keyHour, time.hour);
    await prefs.setInt(_keyMinute, time.minute);
    await requestPermission();
    return scheduleFromPreferences();
  }

  Future<bool> scheduleFromPreferences() async {
    if (!await isEnabled()) return false;
    try {
      await _ensureInitialized();
      if (!_initialized) return false;

      await requestNotificationPermission();
      await _requestExactAlarmPermissionIfNeeded();
      await _configureLocalTimeZone();
      if (!_timezoneReady) return false;

      final time = await getReminderTime();
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.cancel(scheduledNotificationId);
      final mode = await _preferredScheduleMode();
      try {
        await _plugin.zonedSchedule(
          scheduledNotificationId,
          scheduledTitle,
          scheduledBody,
          scheduled,
          _notificationDetails,
          androidScheduleMode: mode,
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        return true;
      } catch (_) {
        if (mode == AndroidScheduleMode.exactAllowWhileIdle) {
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
          return true;
        }
      }
    } catch (e) {
      _lastInitError = '定时注册失败: $e';
    }
    return false;
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

  Future<NotificationActionResult> showTestNotification() async {
    try {
      await initialize(force: true);
      if (!_initialized) return NotificationActionResult.initFailed;

      final granted = await requestNotificationPermission();
      if (!granted) return NotificationActionResult.permissionDenied;

      await _plugin.show(
        testNotificationId,
        '提醒测试',
        '若能看到这条通知，说明推送通道已正常工作',
        _notificationDetails,
      );
      return NotificationActionResult.success;
    } catch (e) {
      _lastInitError = '测试通知失败: $e';
      return NotificationActionResult.failed;
    }
  }

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
      await _ensureInitialized();
      if (!_initialized) return;
      final granted = await requestNotificationPermission();
      if (!granted) return;
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
