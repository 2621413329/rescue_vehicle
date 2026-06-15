import '../../../core/constants/app_colors.dart';

enum InventoryFilter { all, nearExpiry, expired, needLabel, needReplace }

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.itemName,
    required this.batchNo,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    required this.remainingDays,
    required this.cartName,
    required this.layerName,
    required this.riskLevel,
    required this.labelStatus,
    this.managerName,
  });

  final int id;
  final String itemName;
  final String batchNo;
  final num quantity;
  final String unit;
  final String expiryDate;
  final int remainingDays;
  final String cartName;
  final String layerName;
  final RiskLevel riskLevel;
  final String labelStatus;
  final String? managerName;
}
