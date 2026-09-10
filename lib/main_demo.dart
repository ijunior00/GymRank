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
import 'package:gymrank/demo/fake_repositories.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/body_measurement/presentation/controllers/body_measurement_providers.dart';
import 'package:gymrank/features/challenges/presentation/controllers/challenge_providers.dart';
import 'package:gymrank/features/championships/presentation/controllers/championship_providers.dart';
import 'package:gymrank/features/checkin/presentation/controllers/checkin_providers.dart';
import 'package:gymrank/features/coach_panel/presentation/controllers/coach_panel_providers.dart';
import 'package:gymrank/features/friendship/presentation/controllers/friendship_providers.dart';
import 'package:gymrank/features/gamification/presentation/controllers/achievement_providers.dart';
import 'package:gymrank/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:gymrank/features/profile/presentation/controllers/user_repository_provider.dart';
import 'package:gymrank/features/progress_photo/presentation/controllers/progress_photo_providers.dart';
import 'package:gymrank/features/rankings/presentation/controllers/ranking_providers.dart';
import 'package:gymrank/features/rewards/presentation/controllers/reward_providers.dart';
import 'package:gymrank/features/social_feed/presentation/controllers/feed_providers.dart';
import 'package:gymrank/features/workout/presentation/controllers/workout_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(AppConstants.localeTag);
  runApp(
    ProviderScope(
      // Substitui cada repositório concreto (Firebase) por um fake
      // in-memory. Os StreamProviders derivados passam a servir os dados
      // de DemoData automaticamente, então nenhuma outra camada muda.
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        userRepositoryProvider.overrideWithValue(FakeUserRepository()),
        bodyMeasurementRepositoryProvider
            .overrideWithValue(FakeBodyMeasurementRepository()),
        progressPhotoRepositoryProvider
            .overrideWithValue(FakeProgressPhotoRepository()),
        checkInRepositoryProvider.overrideWithValue(FakeCheckInRepository()),
        workoutRepositoryProvider.overrideWithValue(FakeWorkoutRepository()),
        rankingRepositoryProvider.overrideWithValue(FakeRankingRepository()),
        challengeRepositoryProvider
            .overrideWithValue(FakeChallengeRepository()),
        championshipRepositoryProvider
            .overrideWithValue(FakeChampionshipRepository()),
        rewardRepositoryProvider.overrideWithValue(FakeRewardRepository()),
        feedRepositoryProvider.overrideWithValue(FakeFeedRepository()),
        friendshipRepositoryProvider
            .overrideWithValue(FakeFriendshipRepository()),
        notificationRepositoryProvider
            .overrideWithValue(FakeNotificationRepository()),
        achievementRepositoryProvider
            .overrideWithValue(FakeAchievementRepository()),
        coachPanelRepositoryProvider
            .overrideWithValue(FakeCoachPanelRepository()),
      ],
      child: const GymRankDemoApp(),
    ),
  );
}

class GymRankDemoApp extends ConsumerWidget {
  const GymRankDemoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'GymRank (demo)',
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
