import '../../../core/constants/app_colors.dart';

class TodayTasks {
  const TodayTasks({
    required this.pendingInspection,
    required this.completedInspection,
    required this.pendingReplace,
    required this.completedReplace,
    required this.totalReplace,
    required this.pendingLabels,
    required this.completedLabels,
    required this.totalLabels,
    required this.lowStock,
    required this.pendingConfirm,
    required this.pendingExceptions,
  });

  factory TodayTasks.fromJson(Map<String, dynamic> json) => TodayTasks(
        pendingInspection: json['pending_inspection'] as int? ?? 0,
        completedInspection: json['completed_inspection'] as int? ?? 0,
        pendingReplace: json['pending_replace'] as int? ?? 0,
        completedReplace: json['completed_replace'] as int? ?? 0,
        totalReplace: json['total_replace'] as int? ?? 0,
        pendingLabels: json['pending_labels'] as int? ?? 0,
        completedLabels: json['completed_labels'] as int? ?? 0,
        totalLabels: json['total_labels'] as int? ?? 0,
        lowStock: json['low_stock'] as int? ?? 0,
        pendingConfirm: json['pending_confirm'] as int? ?? 0,
        pendingExceptions: json['pending_exceptions'] as int? ?? 0,
      );

  final int pendingInspection;
  final int completedInspection;
  final int pendingReplace;
  final int completedReplace;
  final int totalReplace;
  final int pendingLabels;
  final int completedLabels;
  final int totalLabels;
  final int lowStock;
  final int pendingConfirm;
  final int pendingExceptions;
}

class HealthBoard {
  const HealthBoard({
    required this.cartCount,
    required this.inventoryCount,
    required this.normalCount,
    required this.nearExpiryCount,
    required this.expiredCount,
    required this.lowStockCount,
  });

  factory HealthBoard.fromJson(Map<String, dynamic> json) {
    final total = json['inventory_count'] as int? ?? 0;
    final near = json['near_expiry_count'] as int? ?? 0;
    final expired = json['expired_count'] as int? ?? 0;
    final low = json['low_stock_count'] as int? ?? 0;
    return HealthBoard(
      cartCount: json['cart_count'] as int? ?? 0,
      inventoryCount: total,
      normalCount: total - near - expired,
      nearExpiryCount: near,
      expiredCount: expired,
      lowStockCount: low,
    );
  }

  final int cartCount;
  final int inventoryCount;
  final int normalCount;
  final int nearExpiryCount;
  final int expiredCount;
  final int lowStockCount;
}

class ExpiryForecast {
  const ExpiryForecast({required this.days, required this.label, required this.count});

  factory ExpiryForecast.fromJson(Map<String, dynamic> json) => ExpiryForecast(
        days: json['days'] as int? ?? 0,
        label: json['label'] as String? ?? '',
        count: json['count'] as int? ?? 0,
      );

  final int days;
  final String label;
  final int count;
}

class ReplacePlan {
  const ReplacePlan({required this.period, required this.count, required this.items});

  factory ReplacePlan.fromJson(Map<String, dynamic> json) => ReplacePlan(
        period: json['period'] as String? ?? '',
        count: json['count'] as int? ?? 0,
        items: (json['items'] as List<dynamic>? ?? []).cast<String>(),
      );

  final String period;
  final int count;
  final List<String> items;
}

class CartRiskRank {
  const CartRiskRank({
    required this.rank,
    required this.cartId,
    required this.cartName,
    required this.location,
    required this.riskScore,
    required this.expiredCount,
    required this.nearExpiryCount,
    required this.lowStockCount,
    required this.overdueInspection,
    required this.labelNotUpdated,
  });

  factory CartRiskRank.fromJson(Map<String, dynamic> json) => CartRiskRank(
        rank: json['rank'] as int? ?? 0,
        cartId: json['cart_id'] as int? ?? 0,
        cartName: json['cart_name'] as String? ?? '',
        location: json['location'] as String? ?? '',
        riskScore: json['risk_score'] as int? ?? 0,
        expiredCount: json['expired_count'] as int? ?? 0,
        nearExpiryCount: json['near_expiry_count'] as int? ?? 0,
        lowStockCount: json['low_stock_count'] as int? ?? 0,
        overdueInspection: json['inspection_overdue'] as bool? ?? false,
        labelNotUpdated: json['label_pending_count'] as int? ?? 0,
      );

  final int rank;
  final int cartId;
  final String cartName;
  final String location;
  final int riskScore;
  final int expiredCount;
  final int nearExpiryCount;
  final int lowStockCount;
  final bool overdueInspection;
  final int labelNotUpdated;
}

class RecentAudit {
  const RecentAudit({
    required this.operatorName,
    required this.action,
    required this.target,
    required this.time,
  });

  factory RecentAudit.fromJson(Map<String, dynamic> json) => RecentAudit(
        operatorName: json['operator_name'] as String? ?? '',
        action: json['action'] as String? ?? '',
        target: json['target'] as String? ?? '',
        time: json['time'] as String? ?? '',
      );

  final String operatorName;
  final String action;
  final String target;
  final String time;
}

class DashboardData {
  const DashboardData({
    required this.todayTasks,
    required this.healthBoard,
    required this.expiryForecasts,
    required this.replacePlans,
    required this.labelPending,
    required this.labelNeedUpdate,
    required this.labelNeedPrint,
    required this.cartRisks,
    required this.recentAudits,
    required this.userName,
    required this.departmentName,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final label = json['label_stats'] as Map<String, dynamic>? ?? {};
    return DashboardData(
      userName: json['user_name'] as String? ?? '',
      departmentName: json['department_name'] as String? ?? '',
      todayTasks: TodayTasks.fromJson(json['today_tasks'] as Map<String, dynamic>? ?? {}),
      healthBoard: HealthBoard.fromJson(stats),
      expiryForecasts: (json['expiry_forecasts'] as List<dynamic>? ?? [])
          .map((e) => ExpiryForecast.fromJson(e as Map<String, dynamic>))
          .toList(),
      replacePlans: (json['replace_plans'] as List<dynamic>? ?? [])
          .map((e) => ReplacePlan.fromJson(e as Map<String, dynamic>))
          .toList(),
      labelPending: label['label_pending'] as int? ?? 0,
      labelNeedUpdate: label['label_need_update'] as int? ?? 0,
      labelNeedPrint: label['label_need_print'] as int? ?? 0,
      cartRisks: (json['cart_risks'] as List<dynamic>? ?? [])
          .map((e) => CartRiskRank.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentAudits: (json['recent_audits'] as List<dynamic>? ?? [])
          .map((e) => RecentAudit.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final TodayTasks todayTasks;
  final HealthBoard healthBoard;
  final List<ExpiryForecast> expiryForecasts;
  final List<ReplacePlan> replacePlans;
  final int labelPending;
  final int labelNeedUpdate;
  final int labelNeedPrint;
  final List<CartRiskRank> cartRisks;
  final List<RecentAudit> recentAudits;
  final String userName;
  final String departmentName;
}

RiskLevel riskFromScore(int score) {
  if (score >= 70) return RiskLevel.danger;
  if (score >= 40) return RiskLevel.attention;
  return RiskLevel.normal;
}
