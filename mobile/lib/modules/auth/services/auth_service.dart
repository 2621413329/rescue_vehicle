import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

final authStateProvider = StateProvider<bool>((ref) => false);

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(dioProvider), ref.watch(tokenStorageProvider));
});

class AuthService {
  AuthService(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  Future<void> login(String username, String password) async {
    // FastAPI OAuth2PasswordRequestForm 要求 x-www-form-urlencoded，不能用 JSON
    final body =
        'username=${Uri.encodeQueryComponent(username)}&password=${Uri.encodeQueryComponent(password)}';
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: body,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      ),
    );
    final token = res.data?['access_token'] as String?;
    if (token == null || token.isEmpty) throw Exception('登录失败：未返回 token');
    await _storage.saveToken(token);
  }

  Future<void> logout() async {
    await _storage.clear();
  }

  Future<bool> hasToken() async {
    final t = await _storage.getToken();
    return t != null && t.isNotEmpty;
  }
}
