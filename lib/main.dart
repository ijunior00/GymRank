import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/l10n/app_locale.dart';
import 'package:gymrank/core/router/app_router.dart';
import 'package:gymrank/core/theme/app_theme.dart';
import 'package:gymrank/features/notifications/presentation/controllers/push_registration.dart';
import 'package:gymrank/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    initializeDateFormatting(AppConstants.localeTag),
  ]);
  runApp(const ProviderScope(child: GymRankApp()));
}

class GymRankApp extends ConsumerWidget {
  const GymRankApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Só ler já basta: o provider fica vivo enquanto o app estiver de pé
    // e acompanha login/logout para registrar e apagar o token FCM.
    ref.watch(pushRegistrationProvider);

    return MaterialApp.router(
      title: 'GymRank',
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
