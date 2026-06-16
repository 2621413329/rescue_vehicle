import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../modules/item/models/item_models.dart';
import 'segment_chip_bar.dart';

Future<Map<String, dynamic>?> showItemPickerSheet(
  BuildContext context, {
  required List<Map<String, dynamic>> items,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _ItemPickerSheet(items: items),
  );
}

class _ItemPickerSheet extends StatefulWidget {
  const _ItemPickerSheet({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  State<_ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends State<_ItemPickerSheet> {
  final _search = TextEditingController();
  String? _typeFilter;
  String _keyword = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    var list = widget.items;
    if (_typeFilter != null && _typeFilter!.isNotEmpty) {
      list = list.where((i) => i['item_type'] == _typeFilter).toList();
    }
    if (_keyword.isNotEmpty) {
      list = list
          .where((i) => (i['item_name'] as String? ?? '').contains(_keyword))
          .toList();
    }
    list = [...list]..sort((a, b) => (a['item_name'] as String? ?? '').compareTo(b['item_name'] as String? ?? ''));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('选择药品', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: '搜索药品名称',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _keyword.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _search.clear();
                            setState(() => _keyword = '');
                          },
                        ),
                ),
                onChanged: (v) => setState(() => _keyword = v.trim()),
              ),
            ),
            SegmentChipBar(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              compact: true,
              selectedValue: _typeFilter ?? 'all',
              onSelected: (v) => setState(() => _typeFilter = v == 'all' ? null : v),
              items: [
                const SegmentChipItem(value: 'all', label: '全部'),
                ...ItemTypeLabels.all.map((t) => SegmentChipItem(value: t, label: ItemTypeLabels.label(t))),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text('共 ${list.length} 项', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
            ),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('暂无匹配药品'))
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final item = list[i];
                        final name = item['item_name'] as String? ?? '';
                        final type = ItemTypeLabels.label(item['item_type'] as String?);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(type, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
