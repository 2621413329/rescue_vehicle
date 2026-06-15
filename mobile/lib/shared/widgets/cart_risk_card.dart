import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class CartRiskCard extends StatelessWidget {
  const CartRiskCard({
    super.key,
    required this.rank,
    required this.cartName,
    required this.location,
    required this.riskScore,
    required this.expiredCount,
    required this.nearExpiryCount,
    required this.lowStockCount,
    this.onTap,
  });

  final int rank;
  final String cartName;
  final String location;
  final int riskScore;
  final int expiredCount;
  final int nearExpiryCount;
  final int lowStockCount;
  final VoidCallback? onTap;

  Color get _scoreColor {
    if (riskScore >= 70) return AppColors.danger;
    if (riskScore >= 40) return AppColors.warning;
    return AppColors.normal;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rank <= 3 ? AppColors.dangerBg : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rank <= 3 ? AppColors.danger : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cartName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(location, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (expiredCount > 0) _miniTag('过期 $expiredCount', AppColors.danger),
                        if (nearExpiryCount > 0) _miniTag('临期 $nearExpiryCount', AppColors.warning),
                        if (lowStockCount > 0) _miniTag('不足 $lowStockCount', AppColors.lowStock),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '$riskScore',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _scoreColor,
                    ),
                  ),
                  Text('风险分', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
