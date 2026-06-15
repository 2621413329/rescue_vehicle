import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'risk_tag.dart';

class WarningCard extends StatelessWidget {
  const WarningCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.level,
    required this.time,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final RiskLevel level;
  final String time;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 4,
          height: 48,
          decoration: BoxDecoration(
            color: level.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            RiskTag(level: level, compact: true),
            const SizedBox(height: 4),
            Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
          ],
        ),
      ),
    );
  }
}
