abstract final class ItemTypeLabels {
  static const medicine = 'MEDICINE';
  static const consumable = 'CONSUMABLE';
  static const equipment = 'EQUIPMENT';
  static const rescueSupply = 'RESCUE_SUPPLY';

  static const all = [medicine, consumable, equipment, rescueSupply];

  static String label(String? type) => switch (type) {
        medicine => '药品类',
        consumable => '一次性医用耗材',
        equipment => '诊疗/急救器械',
        rescueSupply => '辅助应急物资',
        _ => type ?? '未知',
      };
}

class MedicineItem {
  const MedicineItem({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.itemType,
    required this.isEnabled,
    required this.updatedAt,
    required this.warningDays,
    this.defaultWarningTag,
    this.operatorName,
    this.inUse = false,
  });

  factory MedicineItem.fromJson(Map<String, dynamic> json) => MedicineItem(
        id: json['id'] as int,
        itemCode: json['item_code'] as String? ?? '',
        itemName: json['item_name'] as String? ?? '',
        itemType: json['item_type'] as String? ?? ItemTypeLabels.medicine,
        isEnabled: json['is_enabled'] as bool? ?? true,
        updatedAt: '${json['updated_at'] ?? ''}',
        warningDays: json['warning_days'] as int? ?? 180,
        defaultWarningTag: json['default_warning_tag'] as String?,
        operatorName: json['operator_name'] as String?,
        inUse: json['in_use'] as bool? ?? false,
      );

  final int id;
  final String itemCode;
  final String itemName;
  final String itemType;
  final bool isEnabled;
  final String updatedAt;
  final int warningDays;
  final String? defaultWarningTag;
  final String? operatorName;
  final bool inUse;

  String get typeLabel => ItemTypeLabels.label(itemType);

  String get warningLabel => defaultWarningTag ?? '${warningDays}天预警';

  String get updatedAtDisplay {
    if (updatedAt.length >= 16) return updatedAt.substring(0, 16).replaceFirst('T', ' ');
    return updatedAt;
  }
}
