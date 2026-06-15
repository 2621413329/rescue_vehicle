import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 配置优先级：`--dart-define=API_BASE_URL` > `.env` 文件 > 默认值
abstract final class EnvConfig {
  static const _defaultEnvFile = '.env';
  static const _fallbackBaseUrl = 'http://127.0.0.1:7080/api/v1';

  /// `--dart-define=ENV_FILE=.env.android.emulator`
  static const envFile = String.fromEnvironment('ENV_FILE', defaultValue: _defaultEnvFile);

  /// Release 打包推荐：`--dart-define=API_BASE_URL=http://172.16.30.130:7080/api/v1`
  static const apiBaseUrlFromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static Future<void> load() async {
    if (dotenv.isInitialized) return;
    try {
      await dotenv.load(fileName: envFile);
    } catch (_) {
      // .env 缺失时仍可使用 dart-define 或默认值
    }
  }

  static String? _env(String key) => dotenv.isInitialized ? dotenv.env[key] : null;

  static String get apiBaseUrl {
    final fromDefine = apiBaseUrlFromDefine.trim();
    if (fromDefine.isNotEmpty) return _normalizeUrl(fromDefine);

    final url = _env('API_BASE_URL')?.trim();
    if (url != null && url.isNotEmpty) return _normalizeUrl(url);
    return _fallbackBaseUrl;
  }

  static String _normalizeUrl(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  static Duration get connectTimeout => Duration(
        seconds: int.tryParse(_env('API_CONNECT_TIMEOUT') ?? '') ?? 15,
      );

  static Duration get receiveTimeout => Duration(
        seconds: int.tryParse(_env('API_RECEIVE_TIMEOUT') ?? '') ?? 15,
      );
}
