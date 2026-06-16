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
    this.statusBadges,
  });

  final String title;
  final String subtitle;
  final RiskLevel level;
  final String time;
  final VoidCallback? onTap;
  final Widget? statusBadges;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 52,
                margin: const EdgeInsets.only(top: 2, right: 10),
                decoration: BoxDecoration(
                  color: level.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (statusBadges != null) ...[
                      const SizedBox(height: 8),
                      statusBadges!,
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RiskTag(level: level, compact: true),
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
