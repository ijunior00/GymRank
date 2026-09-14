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
import 'package:gymrank/features/coach_panel/presentation/widgets/staff_only.dart';
import 'package:gymrank/features/home/presentation/screens/home_dashboard_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting(AppConstants.localeTag);
  });

  _staffOnlyTests();

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

  // O caso que o dono encontrou: ficha aberta pela conta da treinadora e,
  // sem passar pelo logout, a sessão vira a de uma aluna — é o que o
  // Firebase entrega quando a troca aconteceu em outra aba, ou quando o
  // nulo intermediário não chega. Não havendo mudança de "logado /
  // deslogado", nada empurrava a tela para fora, e a aluna ficava vendo
  // um permission-denied cru.
  testWidgets('trocar de conta com a ficha aberta tira a aluna de lá',
      (tester) async {
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

    auth.add(DemoData.uid); // treinadora
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    unawaited(container.read(appRouterProvider).push('/coach/clients/u0'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.byType(ClientDetailScreen), findsOneWidget);

    auth.add('u0'); // a sessão vira a da aluna, sem nulo no meio
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    expect(
      find.byType(ClientDetailScreen),
      findsNothing,
      reason: 'a ficha continuou aberta para a conta de aluna',
    );
    expect(find.byType(HomeDashboardScreen), findsOneWidget);
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

/// O porteiro sozinho, sem depender de como a tela chegou à pilha — é o
/// que protege o caso em que o endereço continua `/home` porque a tela
/// foi empurrada com `context.push`.
void _staffOnlyTests() {
  Future<void> pumpGate(WidgetTester tester, String uid) async {
    final container = ProviderContainer(
      overrides: [
        ...demoOverrides(),
        authStateProvider.overrideWith((ref) => Stream.value(uid)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: appLocale,
          supportedLocales: appSupportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: const StaffOnly(child: Text('painel da coach')),
        ),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  testWidgets('o porteiro deixa a treinadora passar', (tester) async {
    await pumpGate(tester, DemoData.uid);
    expect(find.text('painel da coach'), findsOneWidget);
  });

  testWidgets('o porteiro barra a aluna', (tester) async {
    await pumpGate(tester, 'u0');
    expect(
      find.text('painel da coach'),
      findsNothing,
      reason: 'uma aluna viu o conteúdo de uma tela de coach',
    );
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
