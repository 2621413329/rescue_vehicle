import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';

class WarningTask {
  const WarningTask({
    required this.inventoryId,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.time,
  });

  final int inventoryId;
  final String title;
  final String subtitle;
  final WarningCategory category;
  final String time;
}

enum WarningCategory { nearExpiry, expired, labelUpdate, replace }

RiskLevel categoryLevel(WarningCategory c) => switch (c) {
      WarningCategory.expired => RiskLevel.danger,
      WarningCategory.nearExpiry => RiskLevel.attention,
      WarningCategory.labelUpdate => RiskLevel.attention,
      WarningCategory.replace => RiskLevel.danger,
    };

WarningTask _taskFromInventory(Map<String, dynamic> m, WarningCategory category) {
  final name = m['item_name'] as String? ?? '未知药品';
  final layerNo = m['layer_no'] as int?;
  final layerName = m['layer_name'] as String? ?? '';
  final layer = layerNo != null ? '层级 $layerNo' : (layerName.isEmpty ? '' : layerName);
  final days = m['remaining_days'] as int? ?? 0;
  final id = m['id'] as int? ?? 0;
  final subtitle = layer.isEmpty ? '剩余 $days 天' : '$layer · 剩余 $days 天';
  return WarningTask(
    inventoryId: id,
    title: switch (category) {
      WarningCategory.expired => '$name 已过期',
      WarningCategory.nearExpiry => '$name 临近效期',
      WarningCategory.replace => '$name 待更换',
      WarningCategory.labelUpdate => '$name 待贴标签',
    },
    subtitle: subtitle,
    category: category,
    time: '',
  );
}

final warningListProvider = FutureProvider<List<WarningTask>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final tasks = <WarningTask>[];

  Future<void> addFromQuery(Map<String, dynamic> query, WarningCategory category) async {
    final data = await api.get('/inventories', query: query);
    final items = data['items'] as List<dynamic>? ?? [];
    for (final item in items) {
      tasks.add(_taskFromInventory(item as Map<String, dynamic>, category));
    }
  }

  await addFromQuery({'page': 1, 'page_size': 100, 'is_expired': true}, WarningCategory.expired);
  await addFromQuery({'page': 1, 'page_size': 100, 'is_near_expiry': true}, WarningCategory.nearExpiry);

  final all = await api.get('/inventories', query: {'page': 1, 'page_size': 100});
  final allItems = all['items'] as List<dynamic>? ?? [];
  for (final raw in allItems) {
    final m = raw as Map<String, dynamic>;
    if (m['is_expired'] == true || m['is_near_expiry'] == true) continue;
    final days = m['remaining_days'] as int?;
    final label = m['label_status_text'] as String? ?? '';
    if (days != null && days <= 90) {
      tasks.add(_taskFromInventory(m, WarningCategory.replace));
    } else if (label.contains('待') || label.contains('更新')) {
      tasks.add(_taskFromInventory(m, WarningCategory.labelUpdate));
    }
  }

  final seen = <int>{};
  return tasks.where((t) => seen.add(t.inventoryId)).toList();
});

final warningStatsProvider = FutureProvider<Map<WarningCategory, int>>((ref) async {
  final tasks = await ref.watch(warningListProvider.future);
  return {
    WarningCategory.replace: tasks.where((t) => t.category == WarningCategory.replace).length,
    WarningCategory.labelUpdate: tasks.where((t) => t.category == WarningCategory.labelUpdate).length,
  };
});
