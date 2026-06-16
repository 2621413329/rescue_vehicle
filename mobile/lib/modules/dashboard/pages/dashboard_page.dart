import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/task_card.dart';
import '../models/dashboard_models.dart';
import '../providers/dashboard_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
      data: (data) => RefreshIndicator(
        onRefresh: () => ref.refresh(dashboardProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(data: data)),
            SliverToBoxAdapter(child: _TodayTasksSection(data: data)),
            SliverToBoxAdapter(child: _HealthBoardSection(board: data.healthBoard)),
            SliverToBoxAdapter(child: _ExpiryForecastSection(forecasts: data.expiryForecasts)),
            SliverToBoxAdapter(child: _ReplacePlanSection(plans: data.replacePlans)),
            SliverToBoxAdapter(child: _LabelCenterSection(data: data)),
            SliverToBoxAdapter(child: _RecentAuditSection(audits: data.recentAudits)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = data.todayTasks;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '抢救车效期',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '${data.userName} · ${data.departmentName}',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _headerStat('待更换', '${t.completedReplace}/${t.totalReplace}', sub: '已完成/待更换'),
                const SizedBox(width: 24),
                _headerStat('待贴标签', '${t.completedLabels}/${t.totalLabels}', sub: '已完成/待贴标签'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerStat(String label, String value, {String? sub}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        if (sub != null)
          Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
      ],
    );
  }
}

class _TodayTasksSection extends StatelessWidget {
  const _TodayTasksSection({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = data.todayTasks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '今日待办'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              TaskCard(
                icon: Icons.sync_alt,
                label: '待更换',
                count: t.pendingReplace,
                subLabel: '${t.completedReplace}/${t.totalReplace} 已完成',
                color: AppColors.danger,
                onTap: () => context.push('/warning'),
              ),
              TaskCard(
                icon: Icons.label_outline,
                label: '待贴标签',
                count: t.pendingLabels,
                subLabel: '${t.completedLabels}/${t.totalLabels} 已完成',
                color: AppColors.warning,
                onTap: () => context.push('/label'),
              ),
            ],
          ),
        ),
        if (t.pendingExceptions > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _miniWorkCard('待处理异常', t.pendingExceptions, AppColors.danger),
          ),
      ],
    );
  }

  Widget _miniWorkCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: color)),
          const Spacer(),
          Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _HealthBoardSection extends StatelessWidget {
  const _HealthBoardSection({required this.board});
  final HealthBoard board;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '库存健康看板'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _statCard('库存总数', board.inventoryCount, AppColors.textPrimary),
              _statCard('正常', board.normalCount, AppColors.normal),
              _statCard('临期', board.nearExpiryCount, AppColors.warning),
              _statCard('过期', board.expiredCount, AppColors.danger),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, int value, Color color) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ExpiryForecastSection extends StatelessWidget {
  const _ExpiryForecastSection({required this.forecasts});
  final List<ExpiryForecast> forecasts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '未来有效期计划'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: () {
                  final maxCount = forecasts.fold<int>(0, (m, f) => f.count > m ? f.count : m);
                  return forecasts.map((f) {
                    final ratio = maxCount == 0 ? 0.0 : f.count / maxCount;
                    return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(width: 56, child: Text(f.label, style: const TextStyle(fontSize: 13))),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 20,
                              backgroundColor: AppColors.background,
                              color: _forecastColor(f.days),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('${f.count}项', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  );
                }).toList();
                }(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _forecastColor(int days) {
    if (days <= 30) return AppColors.danger;
    if (days <= 90) return AppColors.warning;
    if (days <= 180) return AppColors.lowStock;
    return AppColors.normal;
  }
}

class _ReplacePlanSection extends StatelessWidget {
  const _ReplacePlanSection({required this.plans});
  final List<ReplacePlan> plans;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '更换计划中心'),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: plans.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final p = plans[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                        if (i < plans.length - 1) Container(width: 2, height: 40, color: AppColors.divider),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(p.period, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
                                child: Text('${p.count}项', style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(p.items.join(' · '), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LabelCenterSection extends StatelessWidget {
  const _LabelCenterSection({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '标签管理中心', actionLabel: '进入', onAction: () => context.push('/label')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: _labelStat('待贴标签', data.labelPending, AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(child: _labelStat('待更新', data.labelNeedUpdate, AppColors.warning)),
              const SizedBox(width: 10),
              Expanded(child: _labelStat('待打印', data.labelNeedPrint, AppColors.lowStock)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _labelStat(String label, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _RecentAuditSection extends StatelessWidget {
  const _RecentAuditSection({required this.audits});
  final List<RecentAudit> audits;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '最近操作记录', actionLabel: '审计日志', onAction: () => context.push('/audit')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: audits.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
              itemBuilder: (context, i) {
                final a = audits[i];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(a.operatorName[0], style: const TextStyle(color: AppColors.primary, fontSize: 14)),
                  ),
                  title: Text('${a.operatorName} ${a.action}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text(a.target, style: const TextStyle(fontSize: 12)),
                  trailing: Text(a.time, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
