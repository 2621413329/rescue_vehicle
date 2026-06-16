import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class TaskStatusBadges extends StatelessWidget {
  const TaskStatusBadges({
    super.key,
    this.replaceDone = false,
    this.labelDone = false,
    this.needsReplace = false,
    this.needsLabel = false,
  });

  final bool replaceDone;
  final bool labelDone;
  final bool needsReplace;
  final bool needsLabel;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (needsReplace || replaceDone) {
      chips.add(_chip(replaceDone ? '已完成' : '待更换', replaceDone ? AppColors.normal : AppColors.danger));
    }
    if (needsLabel || labelDone) {
      chips.add(_chip(labelDone ? '已完成' : '待贴标签', labelDone ? AppColors.normal : AppColors.warning));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: chips,
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
