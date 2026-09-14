// Trocar de conta tem de esvaziar a pilha de telas.
//
// O caso real: a treinadora abre a ficha de uma aluna (tela empurrada
// com `context.push`), sai e entra com uma conta de aluna. Se a ficha
// continuar na pilha, a tela fica lá pedindo dados de coach e o Firestore
// devolve `permission-denied` — a regra faz o certo, quem errou foi a
// navegação.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/l10n/app_locale.dart';
import 'package:gymrank/core/router/app_router.dart';
import 'package:gymrank/core/theme/app_theme.dart';
import 'package:gymrank/demo/demo_data.dart';
import 'package:gymrank/demo/demo_overrides.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/auth/presentation/screens/login_screen.dart';
import 'package:gymrank/features/coach_panel/presentation/screens/client_detail_screen.dart';
import 'package:gymrank/features/home/presentation/screens/home_dashboard_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting(AppConstants.localeTag);
  });

  testWidgets('sair da conta tira as telas empurradas da pilha',
      (tester) async {
    // Quem manda no login aqui é o teste: emite um uid, depois null.
    final auth = StreamController<String?>();
    addTearDown(auth.close);

    final container = ProviderContainer(
      overrides: [
        ...demoOverrides(),
        authStateProvider.overrideWith((ref) => auth.stream),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(),
      ),
    );

    auth.add(DemoData.uid);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.byType(HomeDashboardScreen), findsOneWidget);

    // A treinadora abre a ficha de uma aluna.
    unawaited(container.read(appRouterProvider).push('/coach/clients/u0'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.byType(ClientDetailScreen), findsOneWidget);

    // Sai da conta.
    auth.add(null);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(
      find.byType(ClientDetailScreen),
      findsNothing,
      reason: 'a ficha da aluna continuou empilhada depois do logout',
    );
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('conta de aluna não entra nas telas de coach', (tester) async {
    final auth = StreamController<String?>();
    addTearDown(auth.close);

    final container = ProviderContainer(
      overrides: [
        ...demoOverrides(),
        authStateProvider.overrideWith((ref) => auth.stream),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _TestApp(),
      ),
    );

    // 'u0' é uma aluna do demo (role alumno), não a treinadora.
    auth.add('u0');
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.byType(HomeDashboardScreen), findsOneWidget);

    // Chegar aqui é possível por um link de notificação ou pelo endereço
    // digitado; a guarda do roteador tem de devolvê-la ao início.
    unawaited(container.read(appRouterProvider).push('/coach/clients/u1'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(
      find.byType(ClientDetailScreen),
      findsNothing,
      reason: 'uma aluna abriu a ficha de outra aluna',
    );
    expect(find.byType(HomeDashboardScreen), findsOneWidget);
  });
}

/// Mesma montagem de lib/main.dart: o roteador vem de um `watch`, então o
/// teste passa pelo mesmo caminho de código que o app de verdade.
class _TestApp extends ConsumerWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      theme: AppTheme.dark,
      locale: appLocale,
      supportedLocales: appSupportedLocales,
      localizationsDelegates: appLocalizationsDelegates,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
