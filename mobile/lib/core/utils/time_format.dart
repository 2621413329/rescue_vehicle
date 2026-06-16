import 'package:flutter/material.dart';

String formatTimeZh(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour时$minute分';
}

Future<TimeOfDay?> pickTimeZh(BuildContext context, TimeOfDay initial) {
  return showTimePicker(
    context: context,
    initialTime: initial,
    helpText: '选择提醒时间',
    cancelText: '取消',
    confirmText: '确定',
    hourLabelText: '时',
    minuteLabelText: '分',
  );
}
