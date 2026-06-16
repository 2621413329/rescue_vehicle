import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/segment_chip_bar.dart';
import '../models/item_models.dart';
import '../services/item_service.dart';

final itemListProvider = FutureProvider.autoDispose.family<List<MedicineItem>, String?>((ref, typeFilter) async {
  return ref.read(itemServiceProvider).fetchList(
        itemType: (typeFilter == null || typeFilter.isEmpty) ? null : typeFilter,
      );
});

class ItemListPage extends ConsumerStatefulWidget {
  const ItemListPage({super.key});

  @override
  ConsumerState<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends ConsumerState<ItemListPage> {
  String? _typeFilter;
  final _search = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    ref.invalidate(itemListProvider(_typeFilter));
  }

  Future<void> _disable(MedicineItem item) async {
    if (item.inUse) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('该药品已被库存使用，不可停用')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认停用'),
        content: Text('确定停用「${item.itemName}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('停用')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(itemServiceProvider).disable(item.id);
      await _reload();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已停用')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('停用失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(itemListProvider(_typeFilter));
    return Scaffold(
      appBar: AppBar(title: const Text('药品管理')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final type = _typeFilter;
          final path = type != null && type.isNotEmpty ? '/items/create?type=$type' : '/items/create';
          await context.push(path);
          _reload();
        },
        icon: const Icon(Icons.add),
        label: const Text('新增药品'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: '搜索药品名称',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _search.clear();
                    setState(() => _keyword = '');
                    _reload();
                  },
                ),
              ),
              onSubmitted: (v) {
                setState(() => _keyword = v.trim());
                _reload();
              },
            ),
          ),
          SegmentChipBar(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            compact: true,
            selectedValue: _typeFilter ?? 'all',
            onSelected: (v) {
              setState(() => _typeFilter = v == 'all' ? null : v);
              _reload();
            },
            items: [
              const SegmentChipItem(value: 'all', label: '全部'),
              ...ItemTypeLabels.all.map((t) => SegmentChipItem(value: t, label: ItemTypeLabels.label(t))),
            ],
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
              data: (items) {
                final list = _keyword.isEmpty
                    ? items
                    : items.where((i) => i.itemName.contains(_keyword)).toList();
                if (list.isEmpty) return const Center(child: Text('暂无药品数据'));
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final item = list[i];
                      return Card(
                        child: ListTile(
                          title: Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('类型：${item.typeLabel}'),
                              Text('操作人：${item.operatorName ?? '-'}'),
                              Text('更新时间：${item.updatedAtDisplay}'),
                              if (item.inUse) const Text('已关联库存', style: TextStyle(color: AppColors.warning)),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: item.isEnabled ? AppColors.primaryLight : AppColors.danger.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.isEnabled ? '启用' : '停用',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: item.isEnabled ? AppColors.primary : AppColors.danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () async {
                            await context.push('/items/${item.id}/edit');
                            _reload();
                          },
                          onLongPress: item.isEnabled ? () => _disable(item) : null,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ItemEditPage extends ConsumerStatefulWidget {
  const ItemEditPage({super.key, this.id, this.initialType});

  final int? id;
  final String? initialType;

  @override
  ConsumerState<ItemEditPage> createState() => _ItemEditPageState();
}

class _ItemEditPageState extends ConsumerState<ItemEditPage> {
  final _name = TextEditingController();
  String _type = ItemTypeLabels.medicine;
  bool _loading = false;
  bool _submitting = false;
  MedicineItem? _item;

  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (!_isEdit && widget.initialType != null && ItemTypeLabels.all.contains(widget.initialType)) {
      _type = widget.initialType!;
    }
    if (_isEdit) _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final item = await ref.read(itemServiceProvider).fetchDetail(widget.id!);
      _name.text = item.itemName;
      _type = item.itemType;
      _item = item;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载失败: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写药品名称')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final svc = ref.read(itemServiceProvider);
      if (_isEdit) {
        await svc.update(id: widget.id!, itemName: name, itemType: _type);
      } else {
        await svc.create(itemName: name, itemType: _type);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _disable() async {
    if (_item == null) return;
    if (_item!.inUse) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('该药品已被库存使用，不可停用，但可继续编辑')));
      return;
    }
    try {
      await ref.read(itemServiceProvider).disable(_item!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已停用')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('停用失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEdit ? '编辑药品' : '新增药品')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑药品' : '新增药品'),
        actions: [
          if (_isEdit && (_item?.isEnabled ?? false))
            TextButton(onPressed: _disable, child: const Text('停用')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: '药品名称', prefixIcon: Icon(Icons.medication_outlined)),
          ),
          const SizedBox(height: 16),
          const Text('类型', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          TypeOptionGrid(
            selected: _type,
            onSelected: (v) => setState(() => _type = v),
            options: ItemTypeLabels.all
                .map((t) => SegmentChipItem(value: t, label: ItemTypeLabels.label(t)))
                .toList(),
          ),
          if (_isEdit && _item != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('操作人：${_item!.operatorName ?? '-'}'),
                    const SizedBox(height: 4),
                    Text('更新时间：${_item!.updatedAtDisplay}'),
                    if (_item!.inUse)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('已关联库存，不可停用', style: TextStyle(color: AppColors.warning)),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('保存'),
          ),
        ],
      ),
    );
  }
}
