import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';

final profileStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.get('/profile/stats');
});

final currentUserProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.get('/users/me');
});

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      child: Text('${(user['real_name'] as String? ?? '?')[0]}', style: const TextStyle(fontSize: 24, color: AppColors.primary)),
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
              data: (stats) => Column(
                children: [
                  _statRow('今日工作量', stats['today_workload'] as String? ?? ''),
                  _statRow('本月巡检', '${stats['month_inspections']}次'),
                  _statRow('本月处理库存', '${stats['month_inventory_ops']}项'),
                ],
              ),
            ),
            _menuTile(context, Icons.local_hospital_outlined, '抢救车管理', '/cart'),
            _menuTile(context, Icons.label_outline, '标签中心', '/label'),
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
