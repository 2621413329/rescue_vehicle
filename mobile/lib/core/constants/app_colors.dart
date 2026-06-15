import 'package:flutter/material.dart';

/// 医疗风险色彩规范
abstract final class AppColors {
  static const primary = Color(0xFF1677FF);
  static const primaryLight = Color(0xFFE6F4FF);
  static const primaryDark = Color(0xFF0958D9);

  static const background = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const divider = Color(0xFFE8ECF0);

  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFF9CA3AF);

  /// 正常 #52C41A
  static const normal = Color(0xFF52C41A);
  static const normalBg = Color(0xFFF6FFED);

  /// 关注 #FAAD14
  static const warning = Color(0xFFFAAD14);
  static const warningBg = Color(0xFFFFFBE6);

  /// 危险 #FF4D4F
  static const danger = Color(0xFFFF4D4F);
  static const dangerBg = Color(0xFFFFF1F0);

  /// 库存不足 #FA8C16
  static const lowStock = Color(0xFFFA8C16);
  static const lowStockBg = Color(0xFFFFF7E6);

  /// 设备维护 #722ED1
  static const maintenance = Color(0xFF722ED1);
  static const maintenanceBg = Color(0xFFF9F0FF);
}

enum RiskLevel {
  normal,
  attention,
  danger,
  lowStock,
  maintenance;

  Color get color => switch (this) {
        RiskLevel.normal => AppColors.normal,
        RiskLevel.attention => AppColors.warning,
        RiskLevel.danger => AppColors.danger,
        RiskLevel.lowStock => AppColors.lowStock,
        RiskLevel.maintenance => AppColors.maintenance,
      };

  Color get backgroundColor => switch (this) {
        RiskLevel.normal => AppColors.normalBg,
        RiskLevel.attention => AppColors.warningBg,
        RiskLevel.danger => AppColors.dangerBg,
        RiskLevel.lowStock => AppColors.lowStockBg,
        RiskLevel.maintenance => AppColors.maintenanceBg,
      };

  String get label => switch (this) {
        RiskLevel.normal => '正常',
        RiskLevel.attention => '关注',
        RiskLevel.danger => '危险',
        RiskLevel.lowStock => '库存不足',
        RiskLevel.maintenance => '待维护',
      };
}
