import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/warning_card.dart';
import '../providers/warning_provider.dart';

class WarningCenterPage extends ConsumerWidget {
  const WarningCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(warningListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('任务通知')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (tasks) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _categoryGrid(tasks),
            const SizedBox(height: 16),
            const Text('待处理任务', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (tasks.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('暂无待处理任务')))
            else
              ...tasks.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: WarningCard(
                      title: t.title,
                      subtitle: t.subtitle,
                      level: categoryLevel(t.category),
                      time: t.time,
                      onTap: () => context.push(t.route),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _categoryGrid(List<WarningTask> tasks) {
    int count(WarningCategory c) => tasks.where((t) => t.category == c).length;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _catTile('待巡检', count(WarningCategory.maintenance), AppColors.primary, Icons.fact_check),
        _catTile('待更换', count(WarningCategory.nearExpiry) + count(WarningCategory.expired), AppColors.danger, Icons.sync),
        _catTile('待补货', count(WarningCategory.lowStock), AppColors.lowStock, Icons.inventory),
        _catTile('待贴标签', count(WarningCategory.labelUpdate), AppColors.warning, Icons.label),
      ],
    );
  }

  Widget _catTile(String label, int count, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
