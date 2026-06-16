import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/remaining_days_format.dart';

class ExpiryBadge extends StatelessWidget {
  const ExpiryBadge({
    super.key,
    required this.remainingDays,
    this.isPermanent = false,
    this.showLabel = true,
  });

  final int? remainingDays;
  final bool isPermanent;
  final bool showLabel;

  Color get _color {
    if (isPermanent) return AppColors.normal;
    final days = remainingDays;
    if (days == null) return AppColors.normal;
    if (days < 0) return AppColors.danger;
    if (days <= 90) return AppColors.danger;
    if (days <= 180) return AppColors.warning;
    return AppColors.normal;
  }

  String get _text => formatRemainingDaysText(remainingDays, isPermanent: isPermanent);

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
