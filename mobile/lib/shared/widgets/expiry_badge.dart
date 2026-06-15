import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class ExpiryBadge extends StatelessWidget {
  const ExpiryBadge({
    super.key,
    required this.remainingDays,
    this.showLabel = true,
  });

  final int remainingDays;
  final bool showLabel;

  Color get _color {
    if (remainingDays < 0) return AppColors.danger;
    if (remainingDays <= 90) return AppColors.danger;
    if (remainingDays <= 180) return AppColors.warning;
    return AppColors.normal;
  }

  String get _text {
    if (remainingDays < 0) return '已过期 ${remainingDays.abs()}天';
    return '剩余 $remainingDays 天';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            _text,
            style: TextStyle(
              color: _color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
