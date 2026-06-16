import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';

final auditListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.get('/audit-logs', query: {'page': 1, 'page_size': 50});
  return (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
});

class AuditLogPage extends ConsumerWidget {
  const AuditLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(auditListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('审计日志')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (logs) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final log = logs[i];
            return Card(
              child: ListTile(
                onTap: () => context.push('/audit/${log['id']}'),
                title: Text('${log['action_label'] ?? log['operation_type']}', style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('${log['operator_name']} · ${log['target_label'] ?? '${log['module']} #${log['business_id']}'}'),
                trailing: Text('${log['operation_time']}'.length >= 16 ? '${log['operation_time']}'.substring(11, 16) : '${log['operation_time']}', style: const TextStyle(fontSize: 11)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuditDetailPage extends ConsumerWidget {
  const AuditDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('审计详情')),
      body: FutureBuilder(
        future: ref.read(apiClientProvider).get('/audit-logs', query: {'page': 1, 'page_size': 100}).then((data) {
          final items = (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
          return items.firstWhere((e) => e['id'] == id, orElse: () => <String, dynamic>{});
        }),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final log = snapshot.data!;
          if (log.isEmpty) return const Center(child: Text('无记录'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _row('操作', '${log['action_label'] ?? log['operation_type']}'),
              _row('对象', '${log['target_label'] ?? '${log['module']} #${log['business_id']}'}'),
              _row('操作人', '${log['operator_name']}'),
              _row('时间', '${log['operation_time']}'),
              _row('IP', '${log['ip_address'] ?? '-'}'),
              const SizedBox(height: 16),
              const Text('修改前', style: TextStyle(fontWeight: FontWeight.w600)),
              Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('${log['old_data']}'))),
              const SizedBox(height: 16),
              const Text('修改后', style: TextStyle(fontWeight: FontWeight.w600)),
              Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('${log['new_data']}'))),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(k, style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
