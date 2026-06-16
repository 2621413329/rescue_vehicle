String formatLayerNo(int? layerNo) {
  if (layerNo == null) return '-';
  return switch (layerNo) {
    1 => '第一层',
    2 => '第二层',
    3 => '第三层',
    4 => '第四层',
    5 => '第五层',
    _ => '第$layerNo层',
  };
}

String layerNoLabel(Map<String, dynamic> layer) =>
    formatLayerNo(layer['layer_no'] as int?);
