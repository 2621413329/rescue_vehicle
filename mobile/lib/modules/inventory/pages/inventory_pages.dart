import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/default_cart_provider.dart';
import '../../../core/utils/task_actions.dart';
import '../../../shared/widgets/audit_timeline.dart';
import '../../../shared/widgets/expiry_date_field.dart';
import '../../../shared/widgets/inventory_card.dart';
import '../../../core/utils/layer_format.dart';
import '../../../shared/widgets/segment_chip_bar.dart';
import '../../../shared/widgets/task_status_badges.dart';
import '../models/inventory_models.dart';
import '../providers/inventory_provider.dart';

class InventoryListPage extends ConsumerWidget {
  const InventoryListPage({super.key, this.initialFilter});

  final String? initialFilter;

  static InventoryFilter? _parseFilter(String? f) => switch (f) {
        'near_expiry' => InventoryFilter.nearExpiry,
        'expired' => InventoryFilter.expired,
        'need_label' => InventoryFilter.needLabel,
        'need_replace' => InventoryFilter.needReplace,
        _ => null,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parsed = _parseFilter(initialFilter);
    if (parsed != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(inventoryFilterProvider.notifier).state = parsed;
      });
    }
    final filter = ref.watch(inventoryFilterProvider);
    final layerId = ref.watch(inventoryLayerFilterProvider);
    final layersAsync = ref.watch(cartLayersProvider);
    final async = ref.watch(inventoryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('库存管理')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/inventory/create'),
        icon: const Icon(Icons.add),
        label: const Text('新增库存'),
      ),
      body: Column(
        children: [
          _FilterBar(current: filter, onChanged: (f) => ref.read(inventoryFilterProvider.notifier).state = f),
          layersAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (layers) => _LayerFilterBar(
              layers: layers,
              currentLayerId: layerId,
              onChanged: (id) => ref.read(inventoryLayerFilterProvider.notifier).state = id,
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (items) => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => InventoryCard(
                  itemName: items[i].itemName,
                  batchNo: items[i].batchNo,
                  quantity: items[i].quantity,
                  unit: items[i].unit,
                  expiryDate: items[i].expiryDate,
                  remainingDays: items[i].remainingDays,
                  cartName: '',
                  layerName: items[i].layerDisplay,
                  riskLevel: items[i].riskLevel,
                  labelStatus: items[i].labelStatus,
                  managerName: items[i].managerName,
                  taskReplaceDone: items[i].taskReplaceDone,
                  taskLabelDone: items[i].taskLabelDone,
                  needsReplace: items[i].needsReplace,
                  needsLabel: items[i].needsLabel,
                  onTap: () => context.push('/inventory/${items[i].id}'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.current, required this.onChanged});

  final InventoryFilter current;
  final ValueChanged<InventoryFilter> onChanged;

  static const _filters = [
    (InventoryFilter.all, '全部'),
    (InventoryFilter.nearExpiry, '临期'),
    (InventoryFilter.expired, '过期'),
    (InventoryFilter.needLabel, '待标签'),
    (InventoryFilter.needReplace, '待更换'),
  ];

  @override
  Widget build(BuildContext context) {
    return SegmentChipBar(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      compact: true,
      selectedValue: current.name,
      onSelected: (v) => onChanged(InventoryFilter.values.byName(v)),
      items: _filters
          .map((f) => SegmentChipItem(value: f.$1.name, label: f.$2))
          .toList(),
    );
  }
}

class _LayerFilterBar extends StatelessWidget {
  const _LayerFilterBar({
    required this.layers,
    required this.currentLayerId,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> layers;
  final int? currentLayerId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final sorted = [...layers]..sort((a, b) => (a['layer_no'] as int? ?? 0).compareTo(b['layer_no'] as int? ?? 0));
    final byNo = <int, Map<String, dynamic>>{
      for (final l in sorted)
        if (l['layer_no'] != null) l['layer_no'] as int: l,
    };
    return SegmentChipBar(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      compact: true,
      selectedValue: currentLayerId?.toString() ?? 'all',
      onSelected: (v) {
        if (v == 'all') {
          onChanged(null);
        } else if (byNo.values.any((l) => '${l['id']}' == v)) {
          onChanged(int.parse(v));
        }
      },
      items: [
        const SegmentChipItem(value: 'all', label: '全部'),
        for (var n = 1; n <= 5; n++)
          SegmentChipItem(
            value: byNo[n] != null ? '${byNo[n]!['id']}' : 'none_$n',
            label: formatLayerNo(n),
          ),
      ],
    );
  }
}

class InventoryDetailPage extends ConsumerWidget {
  const InventoryDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inventoryDetailProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: const Text('药品详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/inventory/$id/edit'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (item) {
          if (item == null) return const Center(child: Text('未找到'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              InventoryCard(
                itemName: item.itemName,
                batchNo: item.batchNo,
                quantity: item.quantity,
                unit: item.unit,
                expiryDate: item.expiryDate,
                remainingDays: item.remainingDays,
                cartName: '',
                layerName: item.layerDisplay,
                riskLevel: item.riskLevel,
                labelStatus: item.labelStatus,
                managerName: item.managerName,
              ),
              const SizedBox(height: 12),
              TaskStatusBadges(
                replaceDone: item.taskReplaceDone,
                labelDone: item.taskLabelDone,
                needsReplace: item.needsReplace,
                needsLabel: item.needsLabel,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: item.taskReplaceDone
                          ? null
                          : () => performReplaceTask(
                                context,
                                ref,
                                inventoryId: id,
                                itemName: item.itemName,
                                batchNo: item.batchNo,
                                quantity: '${item.quantity}',
                              ),
                      icon: const Icon(Icons.sync_alt, size: 18),
                      label: Text(item.taskReplaceDone ? '已更换' : '标记已更换'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: item.taskLabelDone
                          ? null
                          : () => performLabelTask(context, ref, inventoryId: id, itemName: item.itemName),
                      icon: const Icon(Icons.label_outline, size: 18),
                      label: Text(item.taskLabelDone ? '已贴标签' : '标记已贴标签'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('生命周期', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _TimelineSection(inventoryId: id),
            ],
          );
        },
      ),
    );
  }
}

class _TimelineSection extends ConsumerWidget {
  const _TimelineSection({required this.inventoryId});

  final int inventoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inventoryTimelineProvider(inventoryId));
    return async.when(
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))),
      error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('加载时间轴失败: $e'))),
      data: (items) => items.isEmpty
          ? Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text('暂无生命周期记录', style: TextStyle(color: Colors.grey.shade600)),
                ),
              ),
            )
          : Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AuditTimeline(
            items: items.asMap().entries.map((e) {
              final m = e.value;
              return AuditTimelineItem(
                title: m['title'] as String? ?? '',
                operatorName: m['operator_name'] as String? ?? '',
                time: m['time'] as String? ?? '',
                detail: m['detail'] as String? ?? '',
                isLast: e.key == items.length - 1,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class InventoryEditPage extends ConsumerStatefulWidget {
  const InventoryEditPage({super.key, required this.id});

  final int id;

  @override
  ConsumerState<InventoryEditPage> createState() => _InventoryEditPageState();
}

class _InventoryEditPageState extends ConsumerState<InventoryEditPage> {
  final _reason = TextEditingController();
  final _quantity = TextEditingController();
  final _batchNo = TextEditingController();
  final _expiryDate = TextEditingController();
  bool _submitting = false;
  bool _initialized = false;

  @override
  void dispose() {
    _reason.dispose();
    _quantity.dispose();
    _batchNo.dispose();
    _expiryDate.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写操作原因')));
      return;
    }
    final qty = int.tryParse(_quantity.text.trim());
    if (qty == null || qty < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数量必须为整数')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(inventoryServiceProvider).update(
            id: widget.id,
            quantity: qty,
            batchNo: _batchNo.text.trim().isEmpty ? null : _batchNo.text.trim(),
            expiryDate: _expiryDate.text.trim().isEmpty ? null : _expiryDate.text.trim(),
            operationReason: _reason.text.trim(),
          );
      ref.invalidate(inventoryListProvider);
      ref.invalidate(inventoryDetailProvider(widget.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(inventoryDetailProvider(widget.id));
    detail.whenData((item) {
      if (item != null && !_initialized) {
        _initialized = true;
        _quantity.text = '${item.quantity.round()}';
        _batchNo.text = item.batchNo;
        _expiryDate.text = item.expiryDate.length >= 10 ? item.expiryDate.substring(0, 10) : item.expiryDate;
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('编辑库存')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (item) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (item != null)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.itemName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text('${item.cartName} · 层级 ${item.layerDisplay}', style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _quantity,
                      decoration: const InputDecoration(
                        labelText: '数量',
                        hintText: '请输入整数',
                        suffixText: '件',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: _batchNo, decoration: const InputDecoration(labelText: '批号')),
                    const SizedBox(height: 16),
                    ExpiryDateField(controller: _expiryDate),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _reason,
                      decoration: const InputDecoration(
                        labelText: '操作原因',
                        hintText: '请说明本次修改原因',
                        helperText: '必填',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}

class InventoryHistoryPage extends ConsumerWidget {
  const InventoryHistoryPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('库存历史')),
      body: _TimelineSection(inventoryId: id),
    );
  }
}

class InventoryCreatePage extends ConsumerStatefulWidget {
  const InventoryCreatePage({super.key});

  @override
  ConsumerState<InventoryCreatePage> createState() => _InventoryCreatePageState();
}

class _InventoryCreatePageState extends ConsumerState<InventoryCreatePage> {
  int? _itemId;
  int? _cartId;
  int? _layerId;
  final _batchNo = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _expiryDate = TextEditingController();
  final _remark = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _layers = [];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _batchNo.dispose();
    _quantity.dispose();
    _expiryDate.dispose();
    _remark.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final cart = await ref.read(defaultCartProvider.future);
      final svc = ref.read(inventoryServiceProvider);
      final items = await svc.fetchItems();
      final layers = await svc.fetchLayers(cart['id'] as int);
      setState(() {
        _cartId = cart['id'] as int;
        _items = items;
        _layers = layers;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载选项失败: $e')));
      }
    }
  }

  Future<void> _submit() async {
    if (_itemId == null || _cartId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择药品')));
      return;
    }
    final qty = int.tryParse(_quantity.text.trim());
    if (qty == null || qty < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数量必须为整数')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(inventoryServiceProvider).create(
            itemId: _itemId!,
            cartId: _cartId!,
            layerId: _layerId,
            batchNo: _batchNo.text.trim(),
            quantity: qty,
            expiryDate: _expiryDate.text.trim(),
            remark: _remark.text.trim(),
          );
      ref.invalidate(inventoryListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('新增成功')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('新增失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('新增库存')), body: const Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('新增库存')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            value: _itemId,
            decoration: const InputDecoration(labelText: '选择药品'),
            items: _items
                .map((i) => DropdownMenuItem(value: i['id'] as int, child: Text(i['item_name'] as String? ?? '')))
                .toList(),
            onChanged: (v) => setState(() => _itemId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _layerId,
            decoration: const InputDecoration(labelText: '层级（可选）'),
            items: _layers
                .map((l) => DropdownMenuItem(value: l['id'] as int, child: Text(layerNoLabel(l))))
                .toList(),
            onChanged: (v) => setState(() => _layerId = v),
          ),
          const SizedBox(height: 12),
          TextField(controller: _batchNo, decoration: const InputDecoration(labelText: '批号')),
          const SizedBox(height: 12),
          TextField(
            controller: _quantity,
            decoration: const InputDecoration(labelText: '数量', hintText: '请输入整数', suffixText: '件'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          ExpiryDateField(controller: _expiryDate, required: true),
          const SizedBox(height: 12),
          TextField(controller: _remark, decoration: const InputDecoration(labelText: '备注')),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('提交'),
          ),
        ],
      ),
    );
  }
}
