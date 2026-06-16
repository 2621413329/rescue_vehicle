import '../../../core/constants/app_colors.dart';
import '../../../core/utils/layer_format.dart';

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
    this.layerNo,
    required this.riskLevel,
    required this.labelStatus,
    this.managerName,
    this.taskReplaceDone = false,
    this.taskLabelDone = false,
    this.isExpired = false,
    this.isNearExpiry = false,
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
  final int? layerNo;
  final RiskLevel riskLevel;
  final String labelStatus;
  final String? managerName;
  final bool taskReplaceDone;
  final bool taskLabelDone;
  final bool isExpired;
  final bool isNearExpiry;

  bool get needsReplace => isExpired || remainingDays <= 0;

  /// 效期 180 天内需贴/更新标签；已完成贴标任务则不再提示。
  bool get needsLabel {
    if (taskLabelDone) return false;
    if (needsReplace) return false;
    return remainingDays <= 180;
  }

  String get layerDisplay {
    if (layerNo != null) return formatLayerNo(layerNo);
    final match = RegExp(r'第?(\d+)').firstMatch(layerName);
    if (match != null) return formatLayerNo(int.tryParse(match.group(1)!));
    return layerName.isEmpty ? '-' : layerName;
  }
}
