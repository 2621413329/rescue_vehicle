import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum LabelStatus { green, yellow, red, pending, needUpdate }

class LabelStatusCard extends StatelessWidget {
  const LabelStatusCard({
    super.key,
    required this.itemName,
    required this.cartName,
    required this.status,
    required this.remainingDays,
    this.selected = false,
    this.onTap,
    this.onSelect,
  });

  final String itemName;
  final String cartName;
  final LabelStatus status;
  final int remainingDays;
  final bool selected;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onSelect;

  Color get _color => switch (status) {
        LabelStatus.green => AppColors.normal,
        LabelStatus.yellow => AppColors.warning,
        LabelStatus.red => AppColors.danger,
        LabelStatus.pending => AppColors.primary,
        LabelStatus.needUpdate => AppColors.lowStock,
      };

  String get _statusText => switch (status) {
        LabelStatus.green => '标签正常',
        LabelStatus.yellow => '待更新标签',
        LabelStatus.red => '需立即更换',
        LabelStatus.pending => '待贴标签',
        LabelStatus.needUpdate => '标签过期',
      };

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
              if (onSelect != null)
                Checkbox(value: selected, onChanged: (v) => onSelect?.call(v ?? false)),
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(itemName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(cartName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_statusText, style: TextStyle(fontSize: 12, color: _color, fontWeight: FontWeight.w600)),
                  Text('剩余$remainingDays天', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
