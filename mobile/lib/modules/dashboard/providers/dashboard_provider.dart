import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/dashboard_models.dart';
import '../services/dashboard_service.dart';

final dashboardServiceProvider = Provider<DashboardApiService>((ref) {
  return DashboardApiService(ref.watch(apiClientProvider));
});

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  return ref.watch(dashboardServiceProvider).fetchDashboard();
});
