import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
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
  await _activateAppCheck();
  runApp(const ProviderScope(child: AnahiFitnessApp()));
}

/// Chave do site reCAPTCHA v3 registrada em App Check (console do
/// Firebase → App Check → app web). Vem de `dart_defines.json`. Vazia =
/// App Check desligado, que é o estado até a chave existir.
const _appCheckSiteKey = String.fromEnvironment('APP_CHECK_RECAPTCHA_SITE_KEY');

/// App Check é o "só o nosso app fala com o backend" do Firebase: cada
/// chamada ao Firestore, Storage e Functions leva um comprovante de que
/// saiu do app de verdade (reCAPTCHA no navegador, Play Integrity no
/// Android, App Attest no iPhone), e não de um script com a chave pública.
/// Ligar aqui não bloqueia nada sozinho: o bloqueio se ativa no console,
/// serviço por serviço, depois de ver nas métricas que os pedidos chegam
/// verificados (docs/seguranca.md).
Future<void> _activateAppCheck() async {
  if (_appCheckSiteKey.isEmpty) return;
  try {
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider(_appCheckSiteKey),
      // Em debug (flutter run) os provedores de loja não funcionam; o de
      // debug imprime um token no console para registrar no App Check.
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );
  } catch (error) {
    // Sem App Check o app segue funcionando (enquanto o console não
    // bloquear). Melhor abrir do que travar na inicialização.
    if (kDebugMode || kIsWeb) debugPrint('App Check não ativou: $error');
  }
}

class AnahiFitnessApp extends ConsumerWidget {
  const AnahiFitnessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Só ler já basta: o provider fica vivo enquanto o app estiver de pé
    // e acompanha login/logout para registrar e apagar o token FCM.
    ref.watch(pushRegistrationProvider);

    return MaterialApp.router(
      title: 'AnahiFitness',
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
