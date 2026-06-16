import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/task_refresh.dart';
import '../../modules/inventory/providers/inventory_provider.dart';
import '../../shared/widgets/replace_confirm_dialog.dart';

Future<void> performReplaceTask(
  BuildContext context,
  WidgetRef ref, {
  required int inventoryId,
  required String itemName,
  String? batchNo,
  String? quantity,
}) async {
  final form = await showReplaceConfirmDialog(
    context,
    itemName: itemName,
    initialBatch: batchNo,
    initialQuantity: quantity,
  );
  if (form == null) return;
  try {
    await ref.read(inventoryServiceProvider).markTaskAction(
          id: inventoryId,
          action: 'REPLACE_DONE',
          expiryDate: form.expiryDate,
          batchNo: form.batchNo,
          quantity: form.quantity != null ? num.tryParse(form.quantity!) : null,
        );
    refreshAfterInventoryTask(ref, inventoryId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已记录更换并更新库存')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    }
  }
}

Future<void> performLabelTask(
  BuildContext context,
  WidgetRef ref, {
  required int inventoryId,
  required String itemName,
}) async {
  final ok = await showLabelConfirmDialog(context, itemName);
  if (!ok) return;
  try {
    await ref.read(inventoryServiceProvider).markTaskAction(id: inventoryId, action: 'LABEL_DONE');
    refreshAfterInventoryTask(ref, inventoryId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已标记贴标签完成')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    }
  }
}

Future<void> performUndoReplaceTask(
  BuildContext context,
  WidgetRef ref, {
  required int inventoryId,
}) async {
  try {
    await ref.read(inventoryServiceProvider).markTaskAction(id: inventoryId, action: 'REPLACE_UNDONE');
    refreshAfterInventoryTask(ref, inventoryId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已撤销更换，恢复为待更换')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    }
  }
}

Future<void> performUndoLabelTask(
  BuildContext context,
  WidgetRef ref, {
  required int inventoryId,
}) async {
  try {
    await ref.read(inventoryServiceProvider).markTaskAction(id: inventoryId, action: 'LABEL_UNDONE');
    refreshAfterInventoryTask(ref, inventoryId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已撤销贴标签，恢复为待贴标签')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    }
  }
}
