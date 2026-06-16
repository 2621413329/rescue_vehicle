import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/auth/services/auth_service.dart';
import '../../modules/warning/providers/warning_provider.dart';
import 'task_reminder_service.dart';

/// 回到前台时重新注册定时通知，并在需要时补发系统级汇总通知。
class ReminderLifecycleHost extends ConsumerStatefulWidget {
  const ReminderLifecycleHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ReminderLifecycleHost> createState() => _ReminderLifecycleHostState();
}

class _ReminderLifecycleHostState extends ConsumerState<ReminderLifecycleHost> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onLaunch());
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _maybeShowSupplementalNotification());
  }

  Future<void> _onLaunch() async {
    final service = TaskReminderService.instance;
    await service.initialize();
    await service.requestNotificationPermissionOnLaunch();
    unawaited(service.scheduleFromPreferences());
    unawaited(_maybeShowSupplementalNotification());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onForeground();
    }
  }

  Future<void> _onForeground() async {
    unawaited(TaskReminderService.instance.scheduleFromPreferences());
    unawaited(_maybeShowSupplementalNotification());
  }

  Future<void> _maybeShowSupplementalNotification() async {
    final loggedIn = ref.read(authStateProvider);
    if (!loggedIn) return;

    final service = TaskReminderService.instance;
    if (!await service.shouldFireSupplementalNotification()) return;

    try {
      final stats = await ref.read(warningStatsProvider.future);
      final replacePending = stats['replacePending'] ?? 0;
      final labelPending = stats['labelPending'] ?? 0;
      await service.showDailySummaryNotification(
        replacePending: replacePending,
        labelPending: labelPending,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
