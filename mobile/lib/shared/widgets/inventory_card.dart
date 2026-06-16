import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'expiry_badge.dart';
import 'risk_tag.dart';
import 'task_status_badges.dart';

class InventoryCard extends StatefulWidget {
  const InventoryCard({
    super.key,
    required this.itemName,
    required this.batchNo,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    required this.remainingDays,
    required this.cartName,
    required this.layerName,
    required this.riskLevel,
    required this.labelStatus,
    this.managerName,
    this.onTap,
    this.taskReplaceDone = false,
    this.taskLabelDone = false,
    this.needsReplace = false,
    this.needsLabel = false,
  });

  final String itemName;
  final String batchNo;
  final num quantity;
  final String unit;
  final String expiryDate;
  final int remainingDays;
  final String cartName;
  final String layerName;
  final RiskLevel riskLevel;
  final String labelStatus;
  final String? managerName;
  final VoidCallback? onTap;
  final bool taskReplaceDone;
  final bool taskLabelDone;
  final bool needsReplace;
  final bool needsLabel;

  @override
  State<InventoryCard> createState() => _InventoryCardState();
}

class _InventoryCardState extends State<InventoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.itemName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  RiskTag(level: widget.riskLevel, compact: true),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _infoChip(Icons.inventory_2_outlined, '${widget.quantity}${widget.unit}'),
                  const SizedBox(width: 12),
                  ExpiryBadge(remainingDays: widget.remainingDays),
                ],
              ),
              if (widget.needsReplace || widget.needsLabel || widget.taskReplaceDone || widget.taskLabelDone) ...[
                const SizedBox(height: 8),
                TaskStatusBadges(
                  replaceDone: widget.taskReplaceDone,
                  labelDone: widget.taskLabelDone,
                  needsReplace: widget.needsReplace,
                  needsLabel: widget.needsLabel,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_hospital_outlined, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.cartName.isEmpty
                          ? '层级 ${widget.layerName}'
                          : '${widget.cartName} · ${widget.layerName}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                ],
              ),
              if (_expanded) ...[
                const Divider(height: 16),
                _detailRow('批号', widget.batchNo),
                _detailRow('有效期', widget.expiryDate),
                _detailRow('标签状态', widget.labelStatus),
                if (widget.managerName != null) _detailRow('责任人', widget.managerName!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
