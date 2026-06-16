import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'expiry_date_field.dart';

class ReplaceFormResult {
  const ReplaceFormResult({
    required this.expiryDate,
    this.batchNo,
    this.quantity,
  });

  final String expiryDate;
  final String? batchNo;
  final String? quantity;
}

Future<ReplaceFormResult?> showReplaceConfirmDialog(
  BuildContext context, {
  required String itemName,
  String? initialBatch,
  String? initialQuantity,
}) {
  final expiry = TextEditingController();
  final batch = TextEditingController(text: initialBatch ?? '');
  final quantity = TextEditingController(text: initialQuantity ?? '1');

  return showDialog<ReplaceFormResult>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('确认更换药品'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('即将更换「$itemName」，请录入新药品信息：', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ExpiryDateField(controller: expiry, required: true),
            const SizedBox(height: 12),
            TextField(controller: batch, decoration: const InputDecoration(labelText: '批号（可选）')),
            const SizedBox(height: 12),
            TextField(
              controller: quantity,
              decoration: const InputDecoration(labelText: '数量'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(
          onPressed: () {
            if (expiry.text.trim().isEmpty) {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('请选择新有效期')));
              return;
            }
            Navigator.pop(
              ctx,
              ReplaceFormResult(
                expiryDate: expiry.text.trim(),
                batchNo: batch.text.trim().isEmpty ? null : batch.text.trim(),
                quantity: quantity.text.trim().isEmpty ? null : quantity.text.trim(),
              ),
            );
          },
          child: const Text('确认更换'),
        ),
      ],
    ),
  );
}

Future<bool> showLabelConfirmDialog(BuildContext context, String itemName) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('确认贴标签'),
      content: Text('确认「$itemName」已完成贴标签？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确认')),
      ],
    ),
  );
  return ok == true;
}
