import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env_config.dart';
import 'modules/auth/services/auth_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();
  runApp(const ProviderScope(child: RescueApp()));
}
class RescueApp extends ConsumerStatefulWidget {
  const RescueApp({super.key});

  @override
  ConsumerState<RescueApp> createState() => _RescueAppState();
}

class _RescueAppState extends ConsumerState<RescueApp> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final has = await ref.read(authServiceProvider).hasToken();
      if (has && mounted) ref.read(authStateProvider.notifier).state = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '抢救车效期',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
