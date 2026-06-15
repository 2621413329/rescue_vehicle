import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class InspectionProgress extends StatelessWidget {
  const InspectionProgress({
    super.key,
    required this.completed,
    required this.total,
    required this.currentLayer,
  });

  final int completed;
  final int total;
  final String currentLayer;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('巡检进度', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('$completed / $total 层', style: const TextStyle(color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.primaryLight,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '当前：$currentLayer',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
