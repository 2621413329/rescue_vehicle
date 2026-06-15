import '../../../core/network/api_client.dart';
import '../models/dashboard_models.dart';

class DashboardApiService {
  DashboardApiService(this._api);

  final ApiClient _api;

  Future<DashboardData> fetchDashboard() async {
    final data = await _api.get('/dashboard/full');
    return DashboardData.fromJson(data);
  }
}
