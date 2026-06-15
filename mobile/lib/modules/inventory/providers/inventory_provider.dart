import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/inventory_models.dart';
import '../services/inventory_service.dart';

final inventoryServiceProvider = Provider<InventoryApiService>((ref) {
  return InventoryApiService(ref.watch(apiClientProvider));
});

final inventoryFilterProvider = StateProvider<InventoryFilter>((ref) => InventoryFilter.all);

final inventoryListProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final filter = ref.watch(inventoryFilterProvider);
  return ref.watch(inventoryServiceProvider).fetchList(filter: filter);
});

final inventoryDetailProvider = FutureProvider.family<InventoryItem?, int>((ref, id) async {
  return ref.watch(inventoryServiceProvider).fetchDetail(id);
});

final inventoryTimelineProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, id) async {
  return ref.watch(inventoryServiceProvider).fetchTimeline(id);
});
