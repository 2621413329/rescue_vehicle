import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';

class WarningTask {
  const WarningTask({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.time,
    required this.route,
  });

  final String title;
  final String subtitle;
  final WarningCategory category;
  final String time;
  final String route;
}

enum WarningCategory { nearExpiry, expired, lowStock, maintenance, labelUpdate }

RiskLevel categoryLevel(WarningCategory c) => switch (c) {
      WarningCategory.expired => RiskLevel.danger,
      WarningCategory.nearExpiry => RiskLevel.attention,
      WarningCategory.lowStock => RiskLevel.lowStock,
      WarningCategory.maintenance => RiskLevel.maintenance,
      WarningCategory.labelUpdate => RiskLevel.attention,
    };

WarningCategory _mapType(String? type) {
  switch (type) {
    case 'EXPIRED':
      return WarningCategory.expired;
    case 'EXPIRY_WARNING':
      return WarningCategory.nearExpiry;
    case 'LOW_STOCK':
      return WarningCategory.lowStock;
    case 'INSPECTION':
      return WarningCategory.maintenance;
    default:
      return WarningCategory.labelUpdate;
  }
}

final warningListProvider = FutureProvider<List<WarningTask>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.get('/notifications', query: {'page': 1, 'page_size': 50, 'is_read': false});
  final items = data['items'] as List<dynamic>? ?? [];
  return items.map((e) {
    final m = e as Map<String, dynamic>;
    return WarningTask(
      title: m['title'] as String? ?? '',
      subtitle: m['content'] as String? ?? '',
      category: _mapType(m['type'] as String?),
      time: (m['created_at'] as String? ?? '').substring(11, 16),
      route: '/inventory',
    );
  }).toList();
});
