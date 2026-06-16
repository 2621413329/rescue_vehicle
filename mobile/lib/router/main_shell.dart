import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_colors.dart';
import '../core/services/task_reminder_service.dart';
import '../modules/warning/providers/warning_provider.dart';
import '../shared/widgets/daily_task_summary_dialog.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TaskReminderService.instance.init();
      _checkDailyReminder();
    });
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _checkDailyReminder());
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
      _checkDailyReminder();
    }
  }

  Future<void> _checkDailyReminder() async {
    final service = TaskReminderService.instance;
    if (!await service.shouldShowInAppDialog()) return;
    if (!mounted) return;

    try {
      final stats = await ref.read(warningStatsProvider.future);
      final replacePending = stats['replacePending'] ?? 0;
      final labelPending = stats['labelPending'] ?? 0;
      if (replacePending + labelPending <= 0) {
        await service.markShownToday();
        return;
      }
      final tasks = await ref.read(warningListProvider.future);
      if (!mounted) return;
      await showDailyTaskSummaryDialog(context, stats: stats, taskCount: tasks.length);
      await service.markShownToday();
      await service.showDailySummaryNotification(
        replacePending: replacePending,
        labelPending: labelPending,
      );
    } catch (_) {
      // 网络异常时跳过，下次再试
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: widget.navigationShell.goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: '首页'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: '库存'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: '任务'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title, style: const TextStyle(color: AppColors.textSecondary))),
    );
  }
}
