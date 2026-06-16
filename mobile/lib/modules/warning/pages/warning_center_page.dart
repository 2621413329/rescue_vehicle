import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/task_actions.dart';
import '../../../shared/widgets/swipe_action_tile.dart';
import '../../../shared/widgets/task_status_badges.dart';
import '../../../shared/widgets/warning_card.dart';
import '../providers/warning_provider.dart';

class WarningCenterPage extends ConsumerWidget {
  const WarningCenterPage({super.key});

  List<SwipeAction> _actions(BuildContext context, WidgetRef ref, WarningTask task) {
    final actions = <SwipeAction>[];

    if (task.needsReplace) {
      if (task.taskReplaceDone) {
        actions.add(
          SwipeAction(
            label: '撤销更换',
            color: AppColors.warning,
            icon: Icons.undo,
            onTap: () => performUndoReplaceTask(context, ref, inventoryId: task.inventoryId),
          ),
        );
      } else {
        actions.add(
          SwipeAction(
            label: '已更换',
            color: AppColors.normal,
            icon: Icons.check_circle_outline,
            onTap: () => performReplaceTask(
              context,
              ref,
              inventoryId: task.inventoryId,
              itemName: task.itemName,
              batchNo: task.batchNo,
              quantity: task.quantity,
            ),
          ),
        );
      }
    }

    if (task.needsLabel) {
      if (task.taskLabelDone) {
        actions.add(
          SwipeAction(
            label: '撤销贴标',
            color: AppColors.warning,
            icon: Icons.undo,
            onTap: () => performUndoLabelTask(context, ref, inventoryId: task.inventoryId),
          ),
        );
      } else {
        actions.add(
          SwipeAction(
            label: '已贴标签',
            color: AppColors.primary,
            icon: Icons.label_outline,
            onTap: () => performLabelTask(context, ref, inventoryId: task.inventoryId, itemName: task.itemName),
          ),
        );
      }
    }

    return actions;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(warningListProvider);
    final stats = ref.watch(warningStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('任务通知')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (tasks) {
          final s = stats.valueOrNull ?? {};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _categoryGrid(s),
              const SizedBox(height: 16),
              const Text('待处理任务', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('左滑显示操作按钮', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('暂无待处理任务')))
              else
                ...tasks.map((t) {
                  final actions = _actions(context, ref, t);
                  final processed = (!t.needsReplace || t.taskReplaceDone) && (!t.needsLabel || t.taskLabelDone);
                  final card = WarningCard(
                    title: t.title,
                    subtitle: t.subtitle,
                    level: categoryLevel(t.category),
                    time: t.time,
                    accentColor: processed ? AppColors.normal : null,
                    statusBadges: TaskStatusBadges(
                      replaceDone: t.taskReplaceDone,
                      labelDone: t.taskLabelDone,
                      needsReplace: t.needsReplace,
                      needsLabel: t.needsLabel,
                    ),
                  );
                  if (actions.isEmpty) {
                    return Padding(padding: const EdgeInsets.only(bottom: 10), child: card);
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SwipeActionTile(actions: actions, child: card),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _categoryGrid(Map<String, int> s) {
    final replaceDone = s['replaceDone'] ?? 0;
    final replaceTotal = s['replaceTotal'] ?? 0;
    final labelDone = s['labelDone'] ?? 0;
    final labelTotal = s['labelTotal'] ?? 0;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _catTile(
          '待更换',
          replaceTotal - replaceDone,
          AppColors.danger,
          Icons.sync,
          replaceTotal == 0 ? '暂无待更换' : '$replaceDone/$replaceTotal 已完成',
        ),
        _catTile(
          '待贴标签',
          labelTotal - labelDone,
          AppColors.warning,
          Icons.label,
          labelTotal == 0 ? '暂无待贴标签' : '$labelDone/$labelTotal 已完成',
        ),
      ],
    );
  }

  Widget _catTile(String label, int count, Color color, IconData icon, String sub) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(sub, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
