import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/label_status_card.dart';

final labelListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.get('/labels', query: {'page': 1, 'page_size': 100});
  return (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
});

class LabelCenterPage extends ConsumerStatefulWidget {
  const LabelCenterPage({super.key});

  @override
  ConsumerState<LabelCenterPage> createState() => _LabelCenterPageState();
}

class _LabelCenterPageState extends ConsumerState<LabelCenterPage> {
  final _selected = <int>{};

  LabelStatus _status(String? s) => switch (s) {
        'RED' => LabelStatus.red,
        'YELLOW' => LabelStatus.yellow,
        'GREEN' => LabelStatus.green,
        _ => LabelStatus.pending,
      };

  Future<void> _batchPrint() async {
    if (_selected.isEmpty) return;
    final api = ref.read(apiClientProvider);
    await api.post('/labels/print', data: {'inventory_ids': _selected.toList()});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('标签打印已记录')));
      ref.invalidate(labelListProvider);
      setState(() => _selected.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(labelListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('标签管理中心'),
        actions: [
          if (_selected.isNotEmpty)
            TextButton(onPressed: _batchPrint, child: Text('批量打印(${_selected.length})')),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selected.isEmpty ? null : _batchPrint,
        icon: const Icon(Icons.print),
        label: const Text('打印标签'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final item = items[i];
            final id = item['inventory_id'] as int;
            return LabelStatusCard(
              itemName: item['item_name'] as String? ?? '',
              cartName: item['cart_name'] as String? ?? '',
              status: _status(item['label_status'] as String?),
              remainingDays: item['remaining_days'] as int? ?? 0,
              selected: _selected.contains(id),
              onSelect: (v) => setState(() {
                if (v) {
                  _selected.add(id);
                } else {
                  _selected.remove(id);
                }
              }),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LabelHistoryPage(inventoryId: id)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LabelHistoryPage extends ConsumerWidget {
  const LabelHistoryPage({super.key, required this.inventoryId});

  final int inventoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('标签历史')),
      body: FutureBuilder(
        future: ref.read(apiClientProvider).getList('/labels/history/$inventoryId'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final m = items[i] as Map<String, dynamic>;
              return ListTile(
                title: Text('${m['label_color']} · ${m['status']}'),
                subtitle: Text('${m['print_time']}'),
              );
            },
          );
        },
      ),
    );
  }
}

class LabelPrintPage extends StatelessWidget {
  const LabelPrintPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LabelCenterPage();
  }
}
