import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';

class ExpiryDateField extends StatelessWidget {
  const ExpiryDateField({
    super.key,
    required this.controller,
    this.label = '有效期',
    this.required = false,
  });

  final TextEditingController controller;
  final String label;
  final bool required;

  static const _quickDays = [90, 180, 365];

  DateTime? _parseDate(String text) {
    if (text.trim().isEmpty) return null;
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(text.trim());
    } catch (_) {
      return null;
    }
  }

  void _applyDate(DateTime date) {
    controller.text = DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _openCalendar(BuildContext context, DateTime initial) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      locale: const Locale('zh', 'CN'),
      helpText: '选择$label',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked != null) {
      _applyDate(picked);
    }
  }

  Future<void> _openPicker(BuildContext context) async {
    final initial = _parseDate(controller.text) ?? DateTime.now().add(const Duration(days: 180));
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('选择$label', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickDays.map((days) {
                  final target = DateTime.now().add(Duration(days: days));
                  final text = DateFormat('yyyy-MM-dd').format(target);
                  return ActionChip(
                    label: Text('$days天 ($text)'),
                    onPressed: () {
                      _applyDate(target);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    await _openCalendar(context, initial);
                  }
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: const Text('打开日历选择'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () => _openPicker(context),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: '点击选择日期',
        suffixIcon: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
        helperText: '可快捷选择 90 / 180 / 365 天',
      ),
    );
  }
}
