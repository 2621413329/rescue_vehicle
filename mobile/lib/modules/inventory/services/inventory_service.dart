import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../models/inventory_models.dart';

class InventoryApiService {
  InventoryApiService(this._api);

  final ApiClient _api;

  RiskLevel _risk(Map<String, dynamic> json) {
    if (json['is_expired'] == true) return RiskLevel.danger;
    if (json['is_near_expiry'] == true) return RiskLevel.attention;
    if (json['is_low_stock'] == true) return RiskLevel.lowStock;
    return RiskLevel.normal;
  }

  InventoryItem _fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id'] as int,
        itemName: json['item_name'] as String? ?? '未知',
        batchNo: json['batch_no'] as String? ?? '',
        quantity: num.tryParse('${json['quantity']}') ?? 0,
        unit: '件',
        expiryDate: '${json['expiry_date'] ?? ''}',
        remainingDays: json['remaining_days'] as int? ?? 0,
        cartName: json['cart_name'] as String? ?? '',
        layerName: json['layer_name'] as String? ?? '',
        riskLevel: _risk(json),
        labelStatus: json['label_status_text'] as String? ?? '',
        managerName: json['manager_name'] as String?,
      );

  Future<List<InventoryItem>> fetchList({InventoryFilter filter = InventoryFilter.all}) async {
    final query = <String, dynamic>{'page': 1, 'page_size': 100};
    switch (filter) {
      case InventoryFilter.nearExpiry:
        query['is_near_expiry'] = true;
      case InventoryFilter.expired:
        query['is_expired'] = true;
      case InventoryFilter.lowStock:
        query['is_low_stock'] = true;
      default:
        break;
    }
    final data = await _api.get('/inventories', query: query);
    final items = data['items'] as List<dynamic>? ?? [];
    var list = items.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    if (filter == InventoryFilter.needLabel) {
      list = list.where((e) => e.labelStatus.contains('待') || e.labelStatus.contains('更新')).toList();
    }
    if (filter == InventoryFilter.needReplace) {
      list = list.where((e) => e.remainingDays <= 90).toList();
    }
    return list;
  }

  Future<InventoryItem?> fetchDetail(int id) async {
    final data = await _api.get('/inventories/$id');
    return _fromJson(data);
  }

  Future<List<Map<String, dynamic>>> fetchTimeline(int id) async {
    return (await _api.getList('/inventories/$id/timeline')).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchItems() async {
    final data = await _api.get('/items', query: {'page': 1, 'page_size': 200});
    return (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchCarts() async {
    final data = await _api.get('/crash-carts', query: {'page': 1, 'page_size': 100});
    return (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchLayers(int cartId) async {
    final data = await _api.get('/crash-carts/layers/list', query: {'cart_id': cartId, 'page': 1, 'page_size': 50});
    return (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  }

  Future<InventoryItem> create({
    required int itemId,
    required int cartId,
    int? layerId,
    String? batchNo,
    required num quantity,
    String? expiryDate,
    String? remark,
  }) async {
    final body = <String, dynamic>{
      'item_id': itemId,
      'cart_id': cartId,
      'quantity': quantity,
      if (layerId != null) 'layer_id': layerId,
      if (batchNo != null && batchNo.isNotEmpty) 'batch_no': batchNo,
      if (expiryDate != null && expiryDate.isNotEmpty) 'expiry_date': expiryDate,
      if (remark != null && remark.isNotEmpty) 'remark': remark,
    };
    final data = await _api.post('/inventories', data: body);
    return _fromJson(data);
  }

  Future<InventoryItem> update({
    required int id,
    num? quantity,
    String? batchNo,
    String? expiryDate,
    required String operationReason,
  }) async {
    final body = <String, dynamic>{
      'operation_reason': operationReason,
      if (quantity != null) 'quantity': quantity,
      if (batchNo != null) 'batch_no': batchNo,
      if (expiryDate != null && expiryDate.isNotEmpty) 'expiry_date': expiryDate,
    };
    final data = await _api.put('/inventories/$id', data: body);
    return _fromJson(data);
  }
}
