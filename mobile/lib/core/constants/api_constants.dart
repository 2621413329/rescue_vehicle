import '../config/env_config.dart';

abstract final class ApiConstants {
  static String get baseUrl => EnvConfig.apiBaseUrl;
  static Duration get connectTimeout => EnvConfig.connectTimeout;
  static Duration get receiveTimeout => EnvConfig.receiveTimeout;
}
