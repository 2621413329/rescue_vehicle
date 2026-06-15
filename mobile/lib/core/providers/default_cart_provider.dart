import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/inventory/services/inventory_service.dart';
import 'api_client.dart';

/// 单抢救车模式：默认使用系统中的第一辆抢救车
final defaultCartProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final data = await ref.watch(apiClientProvider).get('/crash-carts', query: {'page': 1, 'page_size': 1});
  final items = data['items'] as List<dynamic>? ?? [];
  if (items.isEmpty) throw Exception('未配置抢救车');
  return items.first as Map<String, dynamic>;
});

final cartLayersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final cart = await ref.watch(defaultCartProvider.future);
  return ref.watch(inventoryServiceProvider).fetchLayers(cart['id'] as int);
});
