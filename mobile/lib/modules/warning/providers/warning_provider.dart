import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';

class WarningTask {
  const WarningTask({
    required this.inventoryId,
    required this.itemName,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.time,
    required this.taskReplaceDone,
    required this.taskLabelDone,
    required this.needsReplace,
    required this.needsLabel,
    this.batchNo,
    this.quantity,
  });

  final int inventoryId;
  final String itemName;
  final String title;
  final String subtitle;
  final WarningCategory category;
  final String time;
  final bool taskReplaceDone;
  final bool taskLabelDone;
  final bool needsReplace;
  final bool needsLabel;
  final String? batchNo;
  final String? quantity;
}

enum WarningCategory { nearExpiry, expired, labelUpdate, replace }

RiskLevel categoryLevel(WarningCategory c) => switch (c) {
      WarningCategory.expired => RiskLevel.danger,
      WarningCategory.nearExpiry => RiskLevel.attention,
      WarningCategory.labelUpdate => RiskLevel.attention,
      WarningCategory.replace => RiskLevel.danger,
    };

bool _needsReplace(Map<String, dynamic> m) {
  final isExpired = m['is_expired'] as bool? ?? false;
  final days = m['remaining_days'] as int? ?? 999;
  return isExpired || days <= 0;
}

WarningCategory _primaryCategory(Map<String, dynamic> m) {
  final isExpired = m['is_expired'] as bool? ?? false;
  final days = m['remaining_days'] as int? ?? 999;
  if (isExpired || days < 0) return WarningCategory.expired;
  if (days == 0) return WarningCategory.replace;
  if (m['is_near_expiry'] == true) return WarningCategory.nearExpiry;
  return WarningCategory.labelUpdate;
}

String _titleFor(Map<String, dynamic> m, WarningCategory category) {
  final name = m['item_name'] as String? ?? '未知药品';
  return switch (category) {
    WarningCategory.expired => '$name 已过期',
    WarningCategory.nearExpiry => '$name 临近效期',
    WarningCategory.replace => '$name 待更换',
    WarningCategory.labelUpdate => '$name 待贴标签',
  };
}

WarningTask? _taskFromInventory(Map<String, dynamic> m) {
  final name = m['item_name'] as String? ?? '未知药品';
  final layerNo = m['layer_no'] as int?;
  final layerName = m['layer_name'] as String? ?? '';
  final layer = layerNo != null ? '层级 $layerNo' : (layerName.isEmpty ? '' : layerName);
  final days = m['remaining_days'] as int? ?? 0;
  final id = m['id'] as int? ?? 0;
  final isNearExpiry = m['is_near_expiry'] as bool? ?? false;
  final replaceDone = m['task_replace_done'] as bool? ?? false;
  final labelDone = m['task_label_done'] as bool? ?? false;
  final label = m['label_status_text'] as String? ?? '';
  final needsReplace = _needsReplace(m);
  final needsLabel = label.contains('待') || label.contains('更新') || label.contains('需立即');

  if (!needsReplace && !needsLabel && !isNearExpiry && !replaceDone && !labelDone) return null;

  final category = _primaryCategory(m);
  final subtitle = layer.isEmpty ? '剩余 $days 天' : '$layer · 剩余 $days 天';
  return WarningTask(
    inventoryId: id,
    itemName: name,
    title: _titleFor(m, category),
    subtitle: subtitle,
    category: category,
    time: '',
    taskReplaceDone: replaceDone,
    taskLabelDone: labelDone,
    needsReplace: needsReplace,
    needsLabel: needsLabel,
    batchNo: m['batch_no'] as String?,
    quantity: '${m['quantity'] ?? ''}',
  );
}

final warningListProvider = FutureProvider<List<WarningTask>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.get('/inventories', query: {'page': 1, 'page_size': 100});
  final items = (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  return items.map(_taskFromInventory).whereType<WarningTask>().toList();
});

final warningStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final tasks = await ref.watch(warningListProvider.future);
  var replaceTotal = 0;
  var replaceDone = 0;
  var labelTotal = 0;
  var labelDone = 0;
  for (final t in tasks) {
    if (t.needsReplace || t.taskReplaceDone) {
      replaceTotal++;
      if (t.taskReplaceDone) replaceDone++;
    }
    if (t.needsLabel || t.taskLabelDone) {
      labelTotal++;
      if (t.taskLabelDone) labelDone++;
    }
  }
  return {
    'replaceTotal': replaceTotal,
    'replaceDone': replaceDone,
    'replacePending': replaceTotal - replaceDone,
    'labelTotal': labelTotal,
    'labelDone': labelDone,
    'labelPending': labelTotal - labelDone,
  };
});
