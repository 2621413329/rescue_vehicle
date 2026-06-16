import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dio/dio.dart';

import '../../../core/config/env_config.dart';
import '../../../core/constants/app_colors.dart';
import '../services/auth_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _username = TextEditingController(text: 'admin');
  final _password = TextEditingController(text: 'admin');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).login(_username.text.trim(), _password.text);
      ref.read(authStateProvider.notifier).state = true;
      if (mounted) context.go('/');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final detail = e.response?.data;
      final msg = detail is Map ? detail['detail']?.toString() : null;
      if (status == 401) {
        setState(() => _error = '用户名或密码错误（默认账号 admin / admin）');
      } else if (status == 422) {
        setState(() => _error = '请求格式错误，请重新安装最新 APK');
      } else if (e.type == DioExceptionType.connectionError) {
        setState(() => _error = '无法连接服务器\n${EnvConfig.apiBaseUrl}');
      } else {
        setState(() => _error = '登录失败（$status）${msg != null ? '：$msg' : ''}');
      }
    } catch (e) {
      setState(() => _error = '登录失败：$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/branding/app_icon.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('救备通', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 48),
              TextField(controller: _username, decoration: const InputDecoration(labelText: '用户名', prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 16),
              TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: '密码', prefixIcon: Icon(Icons.lock_outline))),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _loading ? null : _login,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('登录'),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
