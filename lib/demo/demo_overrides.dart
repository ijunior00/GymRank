// Troca cada repositório do Firebase por um fake in-memory.
//
// Usado pelo preview (lib/main_demo.dart) e pelos testes de layout, para
// que os dois vejam exatamente o mesmo app: se o teste passa, o preview
// que o dono abre no navegador está mostrando a mesma coisa.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/demo/fake_repositories.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/body_measurement/presentation/controllers/body_measurement_providers.dart';
import 'package:gymrank/features/challenges/presentation/controllers/challenge_providers.dart';
import 'package:gymrank/features/championships/presentation/controllers/championship_providers.dart';
import 'package:gymrank/features/checkin/presentation/controllers/checkin_providers.dart';
import 'package:gymrank/features/coach_panel/presentation/controllers/coach_panel_providers.dart';
import 'package:gymrank/features/friendship/presentation/controllers/friendship_providers.dart';
import 'package:gymrank/features/gamification/presentation/controllers/achievement_providers.dart';
import 'package:gymrank/features/meal_log/presentation/controllers/meal_log_providers.dart';
import 'package:gymrank/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:gymrank/features/notifications/presentation/controllers/push_registration.dart';
import 'package:gymrank/features/plans/presentation/controllers/plan_providers.dart';
import 'package:gymrank/features/profile/presentation/controllers/user_repository_provider.dart';
import 'package:gymrank/features/progress_photo/presentation/controllers/progress_photo_providers.dart';
import 'package:gymrank/features/rankings/presentation/controllers/ranking_providers.dart';
import 'package:gymrank/features/rewards/presentation/controllers/reward_providers.dart';
import 'package:gymrank/features/sharing/presentation/controllers/share_providers.dart';
import 'package:gymrank/features/social_feed/presentation/controllers/feed_providers.dart';
import 'package:gymrank/features/workout/presentation/controllers/workout_providers.dart';
import 'package:gymrank/features/workout_session/presentation/controllers/workout_session_providers.dart';

/// Os StreamProviders derivados passam a servir os dados de `DemoData`
/// automaticamente, então nenhuma outra camada do app muda.
List<Override> demoOverrides() => [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      userRepositoryProvider.overrideWithValue(FakeUserRepository()),
      bodyMeasurementRepositoryProvider
          .overrideWithValue(FakeBodyMeasurementRepository()),
      progressPhotoRepositoryProvider
          .overrideWithValue(FakeProgressPhotoRepository()),
      checkInRepositoryProvider.overrideWithValue(FakeCheckInRepository()),
      workoutRepositoryProvider.overrideWithValue(FakeWorkoutRepository()),
      rankingRepositoryProvider.overrideWithValue(FakeRankingRepository()),
      challengeRepositoryProvider.overrideWithValue(FakeChallengeRepository()),
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
      planRepositoryProvider.overrideWithValue(FakePlanRepository()),
      workoutSessionRepositoryProvider
          .overrideWithValue(FakeWorkoutSessionRepository()),
      mealLogRepositoryProvider.overrideWithValue(FakeMealLogRepository()),
      shareRepositoryProvider.overrideWithValue(FakeShareRepository()),
      // Sem Firebase: nada de FirebaseMessaging.
      pushRegistrationProvider.overrideWith((ref) => PushRegistration.disabled(ref)),
    ];
