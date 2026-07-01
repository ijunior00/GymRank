// PREVIEW/DEMO ONLY. Dados fake usados pelo entrypoint lib/main_demo.dart
// para permitir navegar o app inteiro sem Firebase (deploy de teste no
// Render). Nada aqui é usado pelo app real (lib/main.dart).
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/features/body_measurement/domain/entities/body_measurement_entity.dart';
import 'package:gymrank/features/challenges/domain/entities/challenge_entity.dart';
import 'package:gymrank/features/championships/domain/entities/championship_entity.dart';
import 'package:gymrank/features/friendship/domain/entities/friendship_entity.dart';
import 'package:gymrank/features/gamification/domain/entities/achievement_entity.dart';
import 'package:gymrank/features/gym_admin/domain/entities/gym_entity.dart';
import 'package:gymrank/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';
import 'package:gymrank/features/rankings/domain/entities/ranking_entry_entity.dart';
import 'package:gymrank/features/rewards/domain/entities/reward_entity.dart';
import 'package:gymrank/features/social_feed/domain/entities/post_entity.dart';
import 'package:gymrank/features/workout/domain/entities/workout_entity.dart';

abstract final class DemoData {
  static const String uid = 'demo-user';
  static const String gymId = 'gym-1';

  static DateTime _daysAgo(int d) =>
      DateTime.now().subtract(Duration(days: d));

  static UserEntity get user => UserEntity(
        id: uid,
        name: 'Marina Duarte',
        username: 'marina.d',
        photoUrl: null,
        birthDate: DateTime(1996, 4, 12),
        sex: 'feminino',
        heightCm: 168,
        city: 'São Paulo',
        gymId: gymId,
        goal: UserGoal.hipertrofia,
        role: UserRole.aluno,
        level: 14,
        xpTotal: 12850,
        xpCurrentSeason: 3120,
        gymScore: 812,
        currentStreakDays: 23,
        longestStreakDays: 41,
        lastCheckInAt: DateTime.now().subtract(const Duration(hours: 5)),
        plan: SubscriptionPlan.premium,
        createdAt: DateTime(2025, 9, 1),
      );

  static GymEntity get gym => GymEntity(
        id: gymId,
        name: 'IronHouse Vila Mariana',
        city: 'São Paulo',
        logoUrl: null,
        brandColorHex: '#6C5CE7',
        qrCodeSecret: 'demo-secret',
        plan: SubscriptionPlan.premium,
        studentCount: 342,
        activeChallengeCount: 4,
        createdAt: DateTime(2024, 1, 10),
      );

  static GymDashboardStats get gymStats => GymDashboardStats(
        totalStudents: 342,
        checkInsToday: 87,
        checkInsThisWeek: 512,
        newStudentsThisMonth: 28,
        inactiveStudents30d: 19,
        retentionRate: 0.91,
        calculatedAt: DateTime.now(),
      );

  static List<RankingEntryEntity> rankings(
    RankingScope scope,
    RankingCriteria criteria,
  ) {
    final names = [
      ('Carlos Nunes', 934.0),
      ('Marina Duarte', 812.0),
      ('Beatriz Lima', 798.0),
      ('João Prado', 771.0),
      ('Rafael Sousa', 690.0),
      ('Aline Castro', 654.0),
      ('Diego Martins', 610.0),
      ('Priscila Rocha', 587.0),
    ];
    return [
      for (var i = 0; i < names.length; i++)
        RankingEntryEntity(
          userId: names[i].$1 == 'Marina Duarte' ? uid : 'u$i',
          userName: names[i].$1,
          userPhotoUrl: null,
          position: i + 1,
          value: criteria == RankingCriteria.xp
              ? names[i].$2 * 6
              : names[i].$2,
          scope: scope,
          criteria: criteria,
          calculatedAt: DateTime.now(),
        ),
    ];
  }

  static List<ChallengeEntity> get challenges => [
        ChallengeEntity(
          id: 'c1',
          gymId: gymId,
          title: 'Julho Imparável',
          description: 'Treine 20 dias neste mês e garanta XP em dobro.',
          scope: ChallengeScope.academia,
          period: ChallengePeriod.mensal,
          metric: ChallengeMetric.diasTreinados,
          targetValue: 20,
          startsAt: _daysAgo(10),
          endsAt: DateTime.now().add(const Duration(days: 20)),
          xpReward: 500,
          rewardId: 'r1',
          participantCount: 128,
          isActive: true,
          createdAt: _daysAgo(12),
        ),
        ChallengeEntity(
          id: 'c2',
          gymId: null,
          title: 'Desafio 100 km',
          description: 'Acumule 100 km de corrida/esteira no trimestre.',
          scope: ChallengeScope.regional,
          period: ChallengePeriod.mensal,
          metric: ChallengeMetric.distanciaKm,
          targetValue: 100,
          startsAt: _daysAgo(30),
          endsAt: DateTime.now().add(const Duration(days: 45)),
          xpReward: 800,
          rewardId: null,
          participantCount: 402,
          isActive: true,
          createdAt: _daysAgo(31),
        ),
        ChallengeEntity(
          id: 'c3',
          gymId: gymId,
          title: 'Semana do Foco',
          description: 'Faça 5 check-ins esta semana.',
          scope: ChallengeScope.individual,
          period: ChallengePeriod.semanal,
          metric: ChallengeMetric.checkIns,
          targetValue: 5,
          startsAt: _daysAgo(2),
          endsAt: DateTime.now().add(const Duration(days: 5)),
          xpReward: 200,
          rewardId: null,
          participantCount: 64,
          isActive: true,
          createdAt: _daysAgo(2),
        ),
      ];

  static List<ChampionshipEntity> get championships => [
        ChampionshipEntity(
          id: 'ch1',
          gymId: gymId,
          name: 'Copa IronHouse — Temporada 3',
          description: 'Maior Gym Score da unidade leva o pódio e prêmios.',
          startsAt: _daysAgo(15),
          endsAt: DateTime.now().add(const Duration(days: 15)),
          criteria: ChampionshipCriteria.maiorGymScore,
          rewardIds: ['r1', 'r2'],
          participantCount: 210,
          isFinished: false,
          createdAt: _daysAgo(16),
        ),
        ChampionshipEntity(
          id: 'ch2',
          gymId: gymId,
          name: 'Verão em Forma 2026',
          description: 'Quem fez mais check-ins no verão.',
          startsAt: DateTime(2026, 1, 1),
          endsAt: DateTime(2026, 3, 31),
          criteria: ChampionshipCriteria.maisCheckIns,
          rewardIds: ['r3'],
          participantCount: 298,
          isFinished: true,
          createdAt: DateTime(2025, 12, 20),
        ),
      ];

  static List<PostEntity> get feed => [
        PostEntity(
          id: 'p1',
          userId: 'u0',
          authorName: 'Carlos Nunes',
          authorPhotoUrl: null,
          type: PostType.levelUp,
          text: 'Carlos subiu para o nível 20! 🔥',
          imageUrl: null,
          likeCount: 42,
          commentCount: 6,
          shareCount: 2,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        PostEntity(
          id: 'p2',
          userId: 'u2',
          authorName: 'Beatriz Lima',
          authorPhotoUrl: null,
          type: PostType.challengeCompleted,
          text: 'Beatriz concluiu o desafio "Semana do Foco"!',
          imageUrl: null,
          likeCount: 31,
          commentCount: 3,
          shareCount: 1,
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        ),
        PostEntity(
          id: 'p3',
          userId: uid,
          authorName: 'Marina Duarte',
          authorPhotoUrl: null,
          type: PostType.streakMilestone,
          text: 'Marina completou 23 dias de sequência! 💪',
          imageUrl: null,
          likeCount: 58,
          commentCount: 9,
          shareCount: 4,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        PostEntity(
          id: 'p4',
          userId: 'u3',
          authorName: 'João Prado',
          authorPhotoUrl: null,
          type: PostType.personalRecord,
          text: 'João bateu recorde no supino: 110kg!',
          imageUrl: null,
          likeCount: 77,
          commentCount: 12,
          shareCount: 8,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

  static List<UserAchievementEntity> get achievements => [
        UserAchievementEntity(
            code: AchievementCode.primeiroTreino, unlockedAt: _daysAgo(300)),
        UserAchievementEntity(
            code: AchievementCode.sequencia7Dias, unlockedAt: _daysAgo(280)),
        UserAchievementEntity(
            code: AchievementCode.sequencia30Dias, unlockedAt: _daysAgo(120)),
        UserAchievementEntity(
            code: AchievementCode.primeiraFoto, unlockedAt: _daysAgo(250)),
        UserAchievementEntity(
            code: AchievementCode.primeiroAmigo, unlockedAt: _daysAgo(240)),
        UserAchievementEntity(
            code: AchievementCode.primeiroDesafio, unlockedAt: _daysAgo(200)),
        UserAchievementEntity(
            code: AchievementCode.top10, unlockedAt: _daysAgo(30)),
      ];

  static List<AppNotificationEntity> get notifications => [
        AppNotificationEntity(
          id: 'n1',
          userId: uid,
          type: NotificationType.friendOvertook,
          title: 'Carlos ultrapassou você!',
          body: 'Ele está 122 pontos à frente no ranking da academia.',
          deepLink: '/rankings',
          read: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        AppNotificationEntity(
          id: 'n2',
          userId: uid,
          type: NotificationType.newChallenge,
          title: 'Novo desafio disponível',
          body: '"Semana do Foco" começou. Participe!',
          deepLink: '/challenges',
          read: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        AppNotificationEntity(
          id: 'n3',
          userId: uid,
          type: NotificationType.newAchievement,
          title: 'Conquista desbloqueada 🏅',
          body: 'Você entrou no Top 10 da temporada!',
          deepLink: '/achievements',
          read: true,
          createdAt: _daysAgo(1),
        ),
      ];

  static List<BodyMeasurementEntity> get measurements => [
        for (var i = 8; i >= 0; i--)
          BodyMeasurementEntity(
            id: 'm$i',
            userId: uid,
            recordedAt: _daysAgo(i * 14),
            pesoKg: 68.0 - (8 - i) * 0.4,
            percentualGordura: 26.0 - (8 - i) * 0.5,
            massaMuscularKg: 28.0 + (8 - i) * 0.3,
          ),
      ];

  static List<RewardGrantEntity> get rewardGrants => [
        RewardGrantEntity(
          id: 'g1',
          rewardId: 'r1',
          userId: uid,
          sourceType: 'championship',
          sourceId: 'ch2',
          status: RewardStatus.granted,
          grantedAt: _daysAgo(20),
        ),
      ];

  static List<FriendshipEntity> get friendships => [
        FriendshipEntity(
          id: '${uid}_u0',
          requesterId: uid,
          addresseeId: 'u0',
          status: FriendshipStatus.accepted,
          createdAt: _daysAgo(60),
          respondedAt: _daysAgo(59),
        ),
        FriendshipEntity(
          id: 'u5_$uid',
          requesterId: 'u5',
          addresseeId: uid,
          status: FriendshipStatus.pending,
          createdAt: _daysAgo(1),
        ),
      ];

  static List<WorkoutEntity> get workouts => [
        for (var i = 0; i < 5; i++)
          WorkoutEntity(
            id: 'w$i',
            userId: uid,
            date: _daysAgo(i * 2),
            duration: Duration(minutes: 55 + i * 3),
            muscleGroup: MuscleGroup.values[i % MuscleGroup.values.length],
            intensity: WorkoutIntensity.intensa,
            source: WorkoutSource.manual,
            createdAt: _daysAgo(i * 2),
          ),
      ];
}
