import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<void> showDailyTaskSummaryDialog(
  BuildContext context, {
  required Map<String, int> stats,
  required int taskCount,
}) {
  final replacePending = stats['replacePending'] ?? 0;
  final replaceTotal = stats['replaceTotal'] ?? 0;
  final replaceDone = stats['replaceDone'] ?? 0;
  final labelPending = stats['labelPending'] ?? 0;
  final labelTotal = stats['labelTotal'] ?? 0;
  final labelDone = stats['labelDone'] ?? 0;

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('今日任务汇总'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('待处理任务共 $taskCount 项', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _line('待更换', replacePending, replaceDone, replaceTotal),
          const SizedBox(height: 8),
          _line('待贴标签', labelPending, labelDone, labelTotal),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('知道了')),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            context.push('/warning');
          },
          child: const Text('查看任务'),
        ),
      ],
    ),
  );
}

Widget _line(String label, int pending, int done, int total) {
  return Text('$label：待处理 $pending 项 · 已完成 $done/$total');
}
