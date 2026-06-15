import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/item_models.dart';

final itemServiceProvider = Provider<ItemApiService>((ref) {
  return ItemApiService(ref.watch(apiClientProvider));
});

class ItemApiService {
  ItemApiService(this._api);

  final ApiClient _api;

  Future<List<MedicineItem>> fetchList({
    String? itemType,
    String? keyword,
    bool? isEnabled,
  }) async {
    final query = <String, dynamic>{'page': 1, 'page_size': 100};
    if (itemType != null && itemType.isNotEmpty) query['item_type'] = itemType;
    if (keyword != null && keyword.isNotEmpty) query['keyword'] = keyword;
    if (isEnabled != null) query['is_enabled'] = isEnabled;
    final data = await _api.get('/items', query: query);
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((e) => MedicineItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MedicineItem> fetchDetail(int id) async {
    final data = await _api.get('/items/$id');
    return MedicineItem.fromJson(data);
  }

  Future<MedicineItem> create({
    required String itemName,
    required String itemType,
  }) async {
    final data = await _api.post('/items', data: {
      'item_name': itemName,
      'item_type': itemType,
    });
    return MedicineItem.fromJson(data);
  }

  Future<MedicineItem> update({
    required int id,
    required String itemName,
    required String itemType,
  }) async {
    final data = await _api.put('/items/$id', data: {
      'item_name': itemName,
      'item_type': itemType,
    });
    return MedicineItem.fromJson(data);
  }

  Future<MedicineItem> disable(int id) async {
    final data = await _api.post('/items/$id/disable');
    return MedicineItem.fromJson(data);
  }
}
