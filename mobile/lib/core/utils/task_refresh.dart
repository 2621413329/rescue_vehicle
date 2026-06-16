import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/dashboard/providers/dashboard_provider.dart';
import '../../modules/inventory/providers/inventory_provider.dart';
import '../../modules/label/pages/label_pages.dart';
import '../../modules/warning/providers/warning_provider.dart';

void refreshAfterInventoryTask(WidgetRef ref, int inventoryId) {
  ref.invalidate(warningListProvider);
  ref.invalidate(inventoryListProvider);
  ref.invalidate(inventoryDetailProvider(inventoryId));
  ref.invalidate(inventoryTimelineProvider(inventoryId));
  ref.invalidate(dashboardProvider);
  ref.invalidate(labelListProvider);
}
