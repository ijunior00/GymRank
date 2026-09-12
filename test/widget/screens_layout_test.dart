// Abre cada tela em três larguras de celular e falha se alguma estourar
// o espaço (a faixa listrada "BOTTOM OVERFLOWED BY x PIXELS").
//
// Por que este teste existe: no Flutter web esse erro é DESENHADO na tela,
// não escrito no console, então nem o navegador nem o `flutter analyze`
// avisam. Só apareceu quando o dono do projeto abriu o app e viu a faixa.
//
// As telas rodam com os mesmos fakes do preview (`demoOverrides`), então
// o que passa aqui é o que ele vê em `flutter run -t lib/main_demo.dart`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/l10n/app_locale.dart';
import 'package:gymrank/core/theme/app_theme.dart';
import 'package:gymrank/demo/demo_overrides.dart';

import 'package:gymrank/features/auth/presentation/screens/login_screen.dart';
import 'package:gymrank/features/body_measurement/presentation/screens/body_measurement_screen.dart';
import 'package:gymrank/features/challenges/presentation/screens/challenges_screen.dart';
import 'package:gymrank/features/championships/presentation/screens/championships_screen.dart';
import 'package:gymrank/features/checkin/presentation/screens/checkin_screen.dart';
import 'package:gymrank/features/coach_panel/presentation/screens/client_detail_screen.dart';
import 'package:gymrank/features/coach_panel/presentation/screens/coach_dashboard_screen.dart';
import 'package:gymrank/features/coach_panel/presentation/screens/coach_setup_screen.dart';
import 'package:gymrank/features/friendship/presentation/screens/friends_screen.dart';
import 'package:gymrank/features/gamification/presentation/screens/achievements_screen.dart';
import 'package:gymrank/features/home/presentation/screens/home_dashboard_screen.dart';
import 'package:gymrank/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:gymrank/features/plans/presentation/screens/my_plans_screen.dart';
import 'package:gymrank/features/plans/presentation/screens/plan_detail_screen.dart';
import 'package:gymrank/features/profile/presentation/screens/profile_screen.dart';
import 'package:gymrank/features/progress_photo/presentation/screens/progress_photo_screen.dart';
import 'package:gymrank/features/rankings/presentation/screens/rankings_screen.dart';
import 'package:gymrank/features/rewards/presentation/screens/my_rewards_screen.dart';
import 'package:gymrank/features/social_feed/presentation/screens/feed_screen.dart';
import 'package:gymrank/features/workout/presentation/screens/log_workout_screen.dart';

/// O que aperta o layout: largura de tela e tamanho da fonte do sistema.
/// O iPhone SE ainda é comum entre as alunas, e "fonte grande" é o ajuste
/// de acessibilidade que muita gente deixa ligado — foi exatamente esse
/// caso que estourou a fileira de atalhos do início.
class _Condition {
  const _Condition(this.name, this.size, [this.textScale = 1.0]);
  final String name;
  final Size size;
  final double textScale;
}

const _conditions = <_Condition>[
  _Condition('iPhone SE (320)', Size(320, 568)),
  _Condition('celular normal (412)', Size(412, 915)),
  _Condition('tablet (834)', Size(834, 1112)),
  _Condition('celular con letra grande', Size(412, 915), 1.3),
];

final _screens = <String, Widget Function()>{
  'Inicio': () => const HomeDashboardScreen(),
  'Ranking': () => const RankingsScreen(),
  'Retos': () => const ChallengesScreen(),
  'Comunidad': () => const FeedScreen(),
  'Perfil': () => const ProfileScreen(),
  'Check-in': () => const CheckInScreen(),
  'Registrar entrenamiento': () => const LogWorkoutScreen(),
  'Progreso corporal': () => const BodyMeasurementScreen(),
  'Fotos de progreso': () => const ProgressPhotoScreen(),
  'Logros': () => const AchievementsScreen(),
  'Amigos': () => const FriendsScreen(),
  'Notificaciones': () => const NotificationsScreen(),
  'Torneos': () => const ChampionshipsScreen(),
  'Mis premios': () => const MyRewardsScreen(),
  'Mis planes': () => const MyPlansScreen(),
  'Detalle del plan': () => const PlanDetailScreen(planId: 'plan-coach-ent'),
  'Panel de coach': () => const CoachDashboardScreen(),
  'Configurar coach': () => const CoachSetupScreen(),
  'Ficha de la alumna': () => const ClientDetailScreen(userId: 'u0'),
  'Iniciar sesión': () => const LoginScreen(),
};

void main() {
  setUpAll(() async {
    await initializeDateFormatting(AppConstants.localeTag);
  });

  for (final screen in _screens.entries) {
    for (final condition in _conditions) {
      testWidgets('${screen.key} cabe na tela — ${condition.name}',
          (tester) async {
        tester.view.physicalSize = condition.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final overflows = <String>{};

        await tester.pumpWidget(
          ProviderScope(
            overrides: demoOverrides(),
            child: MaterialApp(
              theme: AppTheme.dark,
              darkTheme: AppTheme.dark,
              themeMode: ThemeMode.dark,
              locale: appLocale,
              supportedLocales: appSupportedLocales,
              localizationsDelegates: appLocalizationsDelegates,
              builder: (context, child) => MediaQuery.withClampedTextScaling(
                minScaleFactor: condition.textScale,
                maxScaleFactor: condition.textScale,
                child: child!,
              ),
              home: screen.value(),
            ),
          ),
        );

        // As telas têm animação de entrada e dados que chegam por stream:
        // avança o relógio em passos até tudo estar desenhado. A cada
        // passo esvazia a fila de erros, senão o teste só reporta o
        // primeiro deles — e no ambiente de teste as imagens da rede
        // sempre falham, barulho que esconderia o que interessa.
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 250));
          for (var error = tester.takeException();
              error != null;
              error = tester.takeException()) {
            final message = error.toString();
            if (message.contains('overflowed')) overflows.add(message);
          }
        }

        expect(
          overflows,
          isEmpty,
          reason: '${screen.key} em ${condition.name} → '
              '${overflows.join(' / ')}',
        );
      });
    }
  }
}
