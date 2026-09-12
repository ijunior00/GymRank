// PREVIEW/DEMO entrypoint. Roda o app inteiro com dados fake e SEM
// Firebase — usado no deploy de teste do Render para validar UI e
// navegação. O app real sempre inicia por lib/main.dart.
//
// O usuário demo é a própria treinadora (papel `coach`), para que o
// painel da coach seja navegável no preview.
//
// Build: flutter build web --release -t lib/main_demo.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/l10n/app_locale.dart';
import 'package:gymrank/core/router/app_router.dart';
import 'package:gymrank/core/theme/app_theme.dart';
import 'package:gymrank/demo/demo_overrides.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(AppConstants.localeTag);
  runApp(
    ProviderScope(
      // Substitui cada repositório concreto (Firebase) por um fake
      // in-memory. Os StreamProviders derivados passam a servir os dados
      // de DemoData automaticamente, então nenhuma outra camada muda.
      overrides: demoOverrides(),
      child: const AnahiFitnessDemoApp(),
    ),
  );
}

class AnahiFitnessDemoApp extends ConsumerWidget {
  const AnahiFitnessDemoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'AnahiFitness (demo)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      locale: appLocale,
      supportedLocales: appSupportedLocales,
      localizationsDelegates: appLocalizationsDelegates,
      routerConfig: router,
    );
  }
}
