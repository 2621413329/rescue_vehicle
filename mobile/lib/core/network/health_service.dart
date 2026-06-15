import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env_config.dart';
import 'api_client.dart';

final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService(ref.watch(dioProvider));
});

class HealthCheckResult {
  const HealthCheckResult({
    required this.ok,
    required this.message,
    this.detail,
  });

  final bool ok;
  final String message;
  final Map<String, dynamic>? detail;
}

class HealthService {
  HealthService(this._dio);

  final Dio _dio;

  Future<HealthCheckResult> check() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/health',
        options: Options(
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final data = res.data ?? {};
      final status = data['status']?.toString() ?? '';
      final reachable = data['reachable'] == true || status == 'ok' || status == 'degraded';
      if (!reachable) {
        return HealthCheckResult(
          ok: false,
          message: '服务器响应异常',
          detail: data,
        );
      }

      final env = data['env']?.toString() ?? '';
      final db = data['database']?.toString() ?? '';
      final app = data['app']?.toString() ?? '后端服务';
      final dbHint = db == 'ok' ? '数据库正常' : '数据库异常';
      final envHint = env.isNotEmpty ? ' · $env' : '';
      return HealthCheckResult(
        ok: db == 'ok',
        message: db == 'ok' ? '已连接 $app$envHint' : '已连通，但$dbHint',
        detail: data,
      );
    } on DioException catch (e) {
      final base = EnvConfig.apiBaseUrl;
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        return HealthCheckResult(ok: false, message: '连接超时，请检查网络与服务器地址\n$base');
      }
      if (e.type == DioExceptionType.connectionError) {
        return HealthCheckResult(ok: false, message: '无法连接服务器，请确认后端已启动且手机与电脑同网段\n$base');
      }
      return HealthCheckResult(ok: false, message: '检测失败：${e.message ?? '未知错误'}\n$base');
    } catch (e) {
      return HealthCheckResult(ok: false, message: '检测失败：$e\n${EnvConfig.apiBaseUrl}');
    }
  }
}
