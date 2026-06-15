import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/inventory_models.dart';
import '../services/inventory_service.dart';

final inventoryServiceProvider = Provider<InventoryApiService>((ref) {
  return InventoryApiService(ref.watch(apiClientProvider));
});

final inventoryFilterProvider = StateProvider<InventoryFilter>((ref) => InventoryFilter.all);
final inventoryLayerFilterProvider = StateProvider<int?>((ref) => null);

final inventoryListProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final filter = ref.watch(inventoryFilterProvider);
  final layerId = ref.watch(inventoryLayerFilterProvider);
  return ref.watch(inventoryServiceProvider).fetchList(filter: filter, layerId: layerId);
});

final inventoryDetailProvider = FutureProvider.family<InventoryItem?, int>((ref, id) async {
  return ref.watch(inventoryServiceProvider).fetchDetail(id);
});

final inventoryTimelineProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, id) async {
  return ref.watch(inventoryServiceProvider).fetchTimeline(id);
});
