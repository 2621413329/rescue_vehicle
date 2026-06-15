import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          storage.clear();
        }
        handler.next(error);
      },
    ),
  );
  return dio;
});

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final res = await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? query,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(path, data: data, queryParameters: query);
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? data}) async {
    final res = await _dio.put<Map<String, dynamic>>(path, data: data);
    return res.data ?? {};
  }

  Future<void> delete(String path, {Map<String, dynamic>? query}) async {
    await _dio.delete(path, queryParameters: query);
  }

  Future<List<dynamic>> getList(String path, {Map<String, dynamic>? query}) async {
    final res = await _dio.get<List<dynamic>>(path, queryParameters: query);
    return res.data ?? [];
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(dioProvider)));
