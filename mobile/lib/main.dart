import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env_config.dart';
import 'core/notifications/reminder_lifecycle_host.dart';
import 'core/notifications/task_reminder_service.dart';
import 'modules/auth/services/auth_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();
  await TaskReminderService.instance.initialize();
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
    return ReminderLifecycleHost(
      child: MaterialApp.router(
        title: '救备通',
        debugShowCheckedModeBanner: false,
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        routerConfig: router,
      ),
    );
  }
}
