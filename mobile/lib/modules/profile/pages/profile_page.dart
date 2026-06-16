import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifications/task_reminder_service.dart';
import '../../../core/utils/time_format.dart';
import '../../auth/services/auth_service.dart';

final profileStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.get('/profile/stats');
});

final currentUserProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.get('/users/me');
});

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 10, minute: 0);
  bool _loaded = false;
  bool _savingReminder = false;

  @override
  void initState() {
    super.initState();
    _loadReminderSettings();
  }

  Future<void> _loadReminderSettings() async {
    final service = TaskReminderService.instance;
    final enabled = await service.isEnabled();
    final time = await service.getReminderTime();
    await service.initialize();
    if (mounted) {
      setState(() {
        _reminderEnabled = enabled;
        _reminderTime = time;
        _loaded = true;
      });
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await pickTimeZh(context, _reminderTime);
    if (picked == null) return;
    setState(() => _savingReminder = true);
    final scheduled = await TaskReminderService.instance.setReminderTime(picked);
    if (!mounted) return;
    setState(() {
      _reminderTime = picked;
      _savingReminder = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          scheduled
              ? '已设置每日 ${formatTimeZh(picked)} 系统提醒'
              : '时间已保存，但定时通知注册失败，请检查通知与闹钟权限',
        ),
      ),
    );
  }

  Future<void> _toggleReminder(bool value) async {
    setState(() {
      _reminderEnabled = value;
      _savingReminder = true;
    });
    final scheduled = await TaskReminderService.instance.setEnabled(value);
    if (!mounted) return;
    setState(() => _savingReminder = false);
    if (value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            scheduled
                ? '已开启每日任务系统提醒'
                : '已开启，但定时通知注册失败，请检查通知与闹钟权限',
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已关闭每日任务提醒')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(profileStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (user) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        (user['real_name'] as String? ?? '?')[0],
                        style: const TextStyle(fontSize: 24, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['real_name'] as String? ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        Text('${user['role']} · ${user['username']}', style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) => _statRow('本月处理库存', '${stats['month_inventory_ops']}项'),
            ),
            if (_loaded) ...[
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: SwitchListTile(
                  title: const Text('每日任务提醒'),
                  subtitle: Text('每天 ${formatTimeZh(_reminderTime)} 系统通知汇总待办'),
                  value: _reminderEnabled,
                  onChanged: _savingReminder ? null : _toggleReminder,
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.schedule, color: AppColors.primary),
                  title: const Text('提醒时间'),
                  subtitle: Text(formatTimeZh(_reminderTime)),
                  trailing: _savingReminder
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.chevron_right),
                  enabled: _reminderEnabled && !_savingReminder,
                  onTap: _reminderEnabled && !_savingReminder ? _pickReminderTime : null,
                ),
              ),
            ],
            _menuTile(context, Icons.medication_outlined, '药品管理', '/items'),
            _menuTile(context, Icons.history, '操作日志', '/audit'),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () async {
                await ref.read(authServiceProvider).logout();
                ref.read(authStateProvider.notifier).state = false;
                if (context.mounted) context.go('/login');
              },
              child: const Text('退出登录'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(title: Text(label), trailing: Text(value, style: const TextStyle(color: AppColors.primary))),
    );
  }

  Widget _menuTile(BuildContext context, IconData icon, String title, String route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(route),
      ),
    );
  }
}
