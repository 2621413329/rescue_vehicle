import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/inspection_progress.dart';

final inspectionTasksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final carts = await api.get('/crash-carts', query: {'page': 1, 'page_size': 50});
  return (carts['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
});

final inspectionHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.get('/inspections', query: {'page': 1, 'page_size': 50});
  return (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
});

class InspectionTaskPage extends ConsumerWidget {
  const InspectionTaskPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inspectionTasksProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('巡检中心'),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () => context.push('/inspection/history')),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/inspection/execute/1'),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('开始巡检'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (carts) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InspectionProgress(completed: 0, total: carts.isEmpty ? 1 : carts.length, currentLayer: '待开始'),
            const SizedBox(height: 16),
            ...carts.map((t) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    onTap: () => context.push('/inspection/execute/${t['id']}'),
                    leading: const Icon(Icons.local_hospital_outlined, color: AppColors.primary),
                    title: Text(t['cart_name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(t['location'] as String? ?? ''),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class InspectionHistoryPage extends ConsumerWidget {
  const InspectionHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inspectionHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('巡检历史')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (records) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final r = records[i];
            return Card(
              child: ListTile(
                title: Text('抢救车 #${r['cart_id']}'),
                subtitle: Text('${r['result']} · ${r['inspection_time']}'),
                onTap: () => context.push('/inspection/detail/${r['id']}'),
              ),
            );
          },
        ),
      ),
    );
  }
}

class InspectionDetailPage extends ConsumerWidget {
  const InspectionDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('巡检详情')),
      body: FutureBuilder(
        future: ref.read(apiClientProvider).get('/inspections/$id'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final r = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _row('抢救车', '${r['cart_id']}'),
              _row('巡检人', '${r['inspector_id']}'),
              _row('结果', '${r['result']}'),
              _row('时间', '${r['inspection_time']}'),
              _row('备注', '${r['remark'] ?? '-'}'),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String k, String v) => ListTile(title: Text(k), subtitle: Text(v));
}

class InspectionExecutePage extends ConsumerStatefulWidget {
  const InspectionExecutePage({super.key, required this.cartId});

  final int cartId;

  @override
  ConsumerState<InspectionExecutePage> createState() => _InspectionExecutePageState();
}

class _InspectionExecutePageState extends ConsumerState<InspectionExecutePage> {
  int _layer = 1;
  int _totalLayers = 3;
  bool _loading = true;
  bool _submitting = false;
  String _result = 'PASS';
  final _remark = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLayers();
  }

  @override
  void dispose() {
    _remark.dispose();
    super.dispose();
  }

  Future<void> _loadLayers() async {
    try {
      final data = await ref.read(apiClientProvider).get('/crash-carts/layers/list', query: {
        'cart_id': widget.cartId,
        'page': 1,
        'page_size': 50,
      });
      final layers = (data['items'] as List<dynamic>? ?? []);
      setState(() {
        _totalLayers = layers.isEmpty ? 3 : layers.length;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitInspection() async {
    setState(() => _submitting = true);
    try {
      await ref.read(apiClientProvider).post('/inspections', data: {
        'cart_id': widget.cartId,
        'inspection_time': DateTime.now().toIso8601String(),
        'result': _result,
        if (_remark.text.trim().isNotEmpty) 'remark': _remark.text.trim(),
      });
      ref.invalidate(inspectionHistoryProvider);
      ref.invalidate(inspectionTasksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('巡检已提交')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提交失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _onNext() {
    if (_layer < _totalLayers) {
      setState(() => _layer++);
    } else {
      _submitInspection();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('执行巡检')), body: const Center(child: CircularProgressIndicator()));
    }
    final isLast = _layer >= _totalLayers;
    return Scaffold(
      appBar: AppBar(title: const Text('执行巡检'), actions: [IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () {})]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InspectionProgress(completed: _layer - 1, total: _totalLayers, currentLayer: '第$_layer层'),
          const SizedBox(height: 24),
          if (isLast) ...[
            DropdownButtonFormField<String>(
              value: _result,
              decoration: const InputDecoration(labelText: '巡检结果'),
              items: const [
                DropdownMenuItem(value: 'PASS', child: Text('合格')),
                DropdownMenuItem(value: 'PARTIAL', child: Text('部分合格')),
                DropdownMenuItem(value: 'FAIL', child: Text('不合格')),
              ],
              onChanged: (v) => setState(() => _result = v ?? 'PASS'),
            ),
            const SizedBox(height: 12),
            TextField(controller: _remark, decoration: const InputDecoration(labelText: '备注（可选）'), maxLines: 2),
            const SizedBox(height: 16),
          ],
          FilledButton(
            onPressed: _submitting ? null : _onNext,
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(isLast ? '完成并提交巡检' : '确认本层，下一层'),
          ),
        ],
      ),
    );
  }
}
