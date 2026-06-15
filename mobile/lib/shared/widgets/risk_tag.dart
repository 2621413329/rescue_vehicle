import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class RiskTag extends StatelessWidget {
  const RiskTag({
    super.key,
    required this.level,
    this.compact = false,
  });

  final RiskLevel level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: level.backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: level.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        level.label,
        style: TextStyle(
          color: level.color,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
