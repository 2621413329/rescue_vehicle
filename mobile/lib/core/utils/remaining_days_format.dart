/// 剩余天数排序：越小越靠前；无有效期排最后。
int remainingDaysSortKey(int? days) => days ?? 999999;

String formatRemainingDaysText(int? days, {required bool isPermanent}) {
  if (isPermanent) return '永久';
  if (days == null) return '永久';
  if (days < 0) return '已过期 ${days.abs()}天';
  return '剩余 $days 天';
}
