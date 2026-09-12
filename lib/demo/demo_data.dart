// PREVIEW/DEMO ONLY. Dados fake usados pelo entrypoint lib/main_demo.dart
// para permitir navegar o app inteiro sem Firebase (deploy de teste no
// Render). Nada aqui é usado pelo app real (lib/main.dart).
//
// O usuário demo é a treinadora (papel `coach`) da comunidade "Método VF",
// com oito alunas/alunos em situações diferentes para exercitar o painel.
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/features/body_measurement/domain/entities/body_measurement_entity.dart';
import 'package:gymrank/features/challenges/domain/entities/challenge_entity.dart';
import 'package:gymrank/features/championships/domain/entities/championship_entity.dart';
import 'package:gymrank/features/coach_panel/domain/entities/client_entity.dart';
import 'package:gymrank/features/coach_panel/domain/entities/coach_entity.dart';
import 'package:gymrank/features/friendship/domain/entities/friendship_entity.dart';
import 'package:gymrank/features/gamification/domain/entities/achievement_entity.dart';
import 'package:gymrank/features/meal_log/domain/entities/meal_log_entity.dart';
import 'package:gymrank/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';
import 'package:gymrank/features/rankings/domain/entities/ranking_entry_entity.dart';
import 'package:gymrank/features/rewards/domain/entities/reward_entity.dart';
import 'package:gymrank/features/sharing/domain/entities/share_card.dart';
import 'package:gymrank/features/sharing/domain/repositories/share_repository.dart';
import 'package:gymrank/features/social_feed/domain/entities/post_entity.dart';
import 'package:gymrank/features/workout/domain/entities/workout_entity.dart';
import 'package:gymrank/features/workout_session/domain/entities/workout_session.dart';

abstract final class DemoData {
  static const String uid = 'demo-coach';
  static const String coachId = 'coach-1';

  static DateTime _daysAgo(int d) =>
      DateTime.now().subtract(Duration(days: d));

  static DateTime _hoursAgo(int h) =>
      DateTime.now().subtract(Duration(hours: h));

  /// A treinadora logada no demo.
  static UserEntity get user => UserEntity(
        id: uid,
        name: 'Valeria Fuentes',
        username: 'vale.fuentes',
        photoUrl: null,
        birthDate: DateTime(1993, 6, 2),
        sex: 'feminino',
        heightCm: 165,
        city: 'Ciudad de México',
        coachId: coachId,
        goal: UserGoal.performance,
        role: UserRole.coach,
        level: 21,
        xpTotal: 24900,
        xpCurrentSeason: 4120,
        gymScore: 934,
        currentStreakDays: 41,
        longestStreakDays: 88,
        lastCheckInAt: _hoursAgo(3),
        plan: SubscriptionPlan.premium,
        referredBy: null,
        referralCount: 0,
        createdAt: DateTime(2025, 9, 1),
      );

  static CoachEntity get coach => CoachEntity(
        id: coachId,
        ownerUserId: uid,
        name: 'Método VF',
        tagline: 'Fuerza, constancia y comunidad',
        city: 'Ciudad de México',
        country: 'MX',
        logoUrl: null,
        brandColorHex: '#FFD60A',
        instagramHandle: 'metodovf',
        inviteCode: 'VF2026',
        qrCodeSecret: 'demo-secret',
        plan: SubscriptionPlan.premium,
        studentCount: 8,
        activeChallengeCount: 3,
        createdAt: DateTime(2025, 9, 1),
      );

  static CoachDashboardStats get coachStats => CoachDashboardStats(
        totalStudents: 8,
        activeStudents: 7,
        workoutsToday: 3,
        workoutsThisWeek: 21,
        newStudentsThisMonth: 2,
        inactiveStudents7d: 2,
        retentionRate: 0.86,
        calculatedAt: DateTime.now(),
      );

  static UserEntity _student({
    required String id,
    required String name,
    required String username,
    required String city,
    required UserGoal goal,
    required int level,
    required int streak,
    required DateTime? lastCheckInAt,
    required int createdDaysAgo,
    int referralCount = 0,
  }) =>
      UserEntity(
        id: id,
        name: name,
        username: username,
        photoUrl: null,
        birthDate: DateTime(1996, 4, 12),
        sex: 'feminino',
        heightCm: 168,
        city: city,
        coachId: coachId,
        goal: goal,
        role: UserRole.alumno,
        level: level,
        xpTotal: level * 600,
        xpCurrentSeason: level * 150,
        gymScore: (level * 42).clamp(0, 1000).toDouble(),
        currentStreakDays: streak,
        longestStreakDays: streak + 12,
        lastCheckInAt: lastCheckInAt,
        plan: SubscriptionPlan.free,
        referredBy: null,
        referralCount: referralCount,
        createdAt: _daysAgo(createdDaysAgo),
      );

  /// Alunas/alunos vinculados à treinadora, cobrindo todos os estados do
  /// painel: al día, en riesgo, sin actividad, sin registros e en pausa.
  static List<UserEntity> get students => [
        _student(
          id: 'u0',
          name: 'Carlos Núñez',
          username: 'carlos.n',
          city: 'Ciudad de México',
          goal: UserGoal.hipertrofia,
          level: 20,
          streak: 31,
          lastCheckInAt: _hoursAgo(3),
          createdDaysAgo: 220,
          referralCount: 3,
        ),
        _student(
          id: 'u1',
          name: 'Fernanda Ríos',
          username: 'fer.rios',
          city: 'Ciudad de México',
          goal: UserGoal.emagrecimento,
          level: 14,
          streak: 23,
          lastCheckInAt: _hoursAgo(5),
          createdDaysAgo: 160,
          referralCount: 1,
        ),
        _student(
          id: 'u2',
          name: 'Diego Prado',
          username: 'diego.p',
          city: 'Guadalajara',
          goal: UserGoal.performance,
          level: 12,
          streak: 9,
          lastCheckInAt: _daysAgo(1),
          createdDaysAgo: 120,
        ),
        _student(
          id: 'u3',
          name: 'Rafael Sosa',
          username: 'rafa.sosa',
          city: 'Monterrey',
          goal: UserGoal.saude,
          level: 9,
          streak: 0,
          lastCheckInAt: _daysAgo(6),
          createdDaysAgo: 90,
        ),
        _student(
          id: 'u4',
          name: 'Ximena Castro',
          username: 'xime.c',
          city: 'Ciudad de México',
          goal: UserGoal.emagrecimento,
          level: 11,
          streak: 4,
          lastCheckInAt: _daysAgo(2),
          createdDaysAgo: 75,
        ),
        _student(
          id: 'u5',
          name: 'Andrés Martínez',
          username: 'andres.mtz',
          city: 'Puebla',
          goal: UserGoal.hipertrofia,
          level: 7,
          streak: 0,
          lastCheckInAt: _daysAgo(16),
          createdDaysAgo: 60,
        ),
        _student(
          id: 'u6',
          name: 'Paola Rocha',
          username: 'pao.rocha',
          city: 'Ciudad de México',
          goal: UserGoal.saude,
          level: 5,
          streak: 2,
          lastCheckInAt: _daysAgo(3),
          createdDaysAgo: 20,
        ),
        _student(
          id: 'u7',
          name: 'Luis Herrera',
          username: 'luis.h',
          city: 'Ciudad de México',
          goal: UserGoal.reabilitacao,
          level: 3,
          streak: 0,
          lastCheckInAt: null,
          createdDaysAgo: 6,
        ),
      ];

  static UserEntity? studentById(String id) {
    for (final s in students) {
      if (s.id == id) return s;
    }
    return null;
  }

  static UserEntity? studentByUsername(String username) {
    final wanted = username.trim().replaceFirst('@', '').toLowerCase();
    for (final s in students) {
      if (s.username.toLowerCase() == wanted) return s;
    }
    return null;
  }

  /// Prêmios da comunidade (o grant só guarda o id, o nome vem daqui).
  static List<RewardEntity> get rewards => [
        const RewardEntity(
          id: 'r1',
          coachId: coachId,
          name: 'Playera oficial Método VF',
          imageUrl: null,
          type: RewardType.vestuario,
          stock: 12,
        ),
        const RewardEntity(
          id: 'r2',
          coachId: coachId,
          name: 'Sesión presencial 1 a 1',
          imageUrl: null,
          type: RewardType.consultoria,
          stock: 3,
        ),
        const RewardEntity(
          id: 'r3',
          coachId: coachId,
          name: 'Mensualidad gratis',
          imageUrl: null,
          type: RewardType.mensalidadeGratis,
          stock: 1,
        ),
      ];

  static RewardEntity? rewardById(String id) {
    for (final r in rewards) {
      if (r.id == id) return r;
    }
    return null;
  }

  static List<ClientEntity> get clients {
    const plans = [
      'Elite',
      'Online mensual',
      'Presencial 3x',
      'Online mensual',
      'Online trimestral',
      'Online mensual',
      null,
      'Online mensual',
    ];
    final list = students;
    return [
      for (var i = 0; i < list.length; i++)
        ClientEntity(
          userId: list[i].id,
          coachId: coachId,
          status: list[i].id == 'u7'
              ? ClientStatus.pausado
              : ClientStatus.activo,
          planName: plans[i],
          startedAt: list[i].createdAt,
          nextPaymentAt: plans[i] == null
              ? null
              : DateTime.now().add(Duration(days: 3 + i * 4)),
          tags: const [],
          lastWorkoutAt: list[i].lastCheckInAt,
          createdAt: list[i].createdAt,
        ),
    ];
  }

  static List<CoachNoteEntity> notes(String userId) {
    if (userId == 'u0') {
      return [
        CoachNoteEntity(
          id: 'n1',
          authorId: uid,
          text: 'Subir carga en sentadilla a 100 kg la próxima semana.',
          createdAt: _daysAgo(2),
        ),
        CoachNoteEntity(
          id: 'n2',
          authorId: uid,
          text: 'Molestia leve en hombro derecho; evitar press militar.',
          createdAt: _daysAgo(9),
        ),
      ];
    }
    if (userId == 'u3') {
      return [
        CoachNoteEntity(
          id: 'n3',
          authorId: uid,
          text: 'Lleva 6 días sin entrenar. Mandarle audio hoy.',
          createdAt: _daysAgo(1),
        ),
      ];
    }
    return const [];
  }

  static List<RankingEntryEntity> rankings(
    RankingScope scope,
    RankingCriteria criteria,
  ) {
    final names = [
      ('Carlos Núñez', 934.0, 'u0'),
      ('Valeria Fuentes', 812.0, uid),
      ('Fernanda Ríos', 798.0, 'u1'),
      ('Diego Prado', 771.0, 'u2'),
      ('Ximena Castro', 690.0, 'u4'),
      ('Rafael Sosa', 654.0, 'u3'),
      ('Andrés Martínez', 610.0, 'u5'),
      ('Paola Rocha', 587.0, 'u6'),
    ];
    return [
      for (var i = 0; i < names.length; i++)
        RankingEntryEntity(
          userId: names[i].$3,
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
          coachId: coachId,
          title: 'Septiembre imparable',
          description: 'Entrena 20 días este mes y gana XP doble.',
          scope: ChallengeScope.comunidad,
          period: ChallengePeriod.mensal,
          metric: ChallengeMetric.diasTreinados,
          targetValue: 20,
          startsAt: _daysAgo(10),
          endsAt: DateTime.now().add(const Duration(days: 20)),
          xpReward: 500,
          rewardId: 'r1',
          participantCount: 8,
          isActive: true,
          createdAt: _daysAgo(12),
        ),
        ChallengeEntity(
          id: 'c2',
          coachId: null,
          title: 'Reto 100 km',
          description:
              'Acumula 100 km de carrera o caminadora en el trimestre.',
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
          coachId: coachId,
          title: 'Semana de enfoque',
          description: 'Completa 5 entrenamientos esta semana.',
          scope: ChallengeScope.individual,
          period: ChallengePeriod.semanal,
          metric: ChallengeMetric.checkIns,
          targetValue: 5,
          startsAt: _daysAgo(2),
          endsAt: DateTime.now().add(const Duration(days: 5)),
          xpReward: 200,
          rewardId: null,
          participantCount: 6,
          isActive: true,
          createdAt: _daysAgo(2),
        ),
      ];

  static List<ChampionshipEntity> get championships => [
        ChampionshipEntity(
          id: 'ch1',
          coachId: coachId,
          name: 'Copa Método VF · Temporada 3',
          description:
              'El mayor Gym Score de la comunidad se lleva el podio y premios.',
          startsAt: _daysAgo(15),
          endsAt: DateTime.now().add(const Duration(days: 15)),
          criteria: ChampionshipCriteria.maiorGymScore,
          rewardIds: ['r1', 'r2'],
          participantCount: 8,
          isFinished: false,
          createdAt: _daysAgo(16),
        ),
        ChampionshipEntity(
          id: 'ch2',
          coachId: coachId,
          name: 'Verano en forma 2026',
          description: 'Quien hizo más check-ins durante el verano.',
          startsAt: DateTime(2026, 6, 1),
          endsAt: DateTime(2026, 8, 31),
          criteria: ChampionshipCriteria.maisCheckIns,
          rewardIds: ['r3'],
          participantCount: 7,
          isFinished: true,
          createdAt: DateTime(2026, 5, 20),
        ),
      ];

  static List<PostEntity> get feed => [
        PostEntity(
          id: 'p1',
          userId: 'u0',
          authorName: 'Carlos Núñez',
          authorPhotoUrl: null,
          type: PostType.levelUp,
          text: '¡Carlos subió al nivel 20! 🔥',
          imageUrl: null,
          likeCount: 42,
          commentCount: 6,
          shareCount: 2,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        PostEntity(
          id: 'p2',
          userId: 'u1',
          authorName: 'Fernanda Ríos',
          authorPhotoUrl: null,
          type: PostType.challengeCompleted,
          text: '¡Fernanda completó el reto "Semana de enfoque"!',
          imageUrl: null,
          likeCount: 31,
          commentCount: 3,
          shareCount: 1,
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        ),
        PostEntity(
          id: 'p3',
          userId: uid,
          authorName: 'Valeria Fuentes',
          authorPhotoUrl: null,
          type: PostType.streakMilestone,
          text: '¡Valeria lleva 41 días de racha! 💪',
          imageUrl: null,
          likeCount: 58,
          commentCount: 9,
          shareCount: 4,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        PostEntity(
          id: 'p4',
          userId: 'u2',
          authorName: 'Diego Prado',
          authorPhotoUrl: null,
          type: PostType.personalRecord,
          text: '¡Diego rompió su récord en press de banca: 110 kg!',
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
          type: NotificationType.newStudent,
          title: 'Nuevo alumno',
          body: 'Luis Herrera se unió a Método VF con tu código.',
          deepLink: '/coach/clients/u7',
          read: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        AppNotificationEntity(
          id: 'n2',
          userId: uid,
          type: NotificationType.newChallenge,
          title: 'Nuevo reto disponible',
          body: '"Semana de enfoque" ya empezó. ¡Únete!',
          deepLink: '/challenges',
          read: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        AppNotificationEntity(
          id: 'n3',
          userId: uid,
          type: NotificationType.newAchievement,
          title: 'Logro desbloqueado 🏅',
          body: 'Entraste al Top 10 de la temporada.',
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

  // --- Planes y documentos ---------------------------------------------------

  static Map<String, dynamic> get workoutPlanContent => {
        'title': 'Fuerza · Bloque 1 (4 semanas)',
        'summary': 'Tres sesiones por semana enfocadas en básicos.',
        'weeksDuration': 4,
        'days': [
          {
            'name': 'Día 1 · Pierna',
            'focus': 'Cuádriceps y glúteo',
            'exercises': [
              {'name': 'Sentadilla con barra', 'sets': 4, 'reps': '6-8', 'load': 'RPE 8', 'restSeconds': 120, 'technique': null, 'notes': null},
              {'name': 'Prensa 45°', 'sets': 3, 'reps': '10-12', 'load': null, 'restSeconds': 90, 'technique': null, 'notes': null},
              {'name': 'Hip thrust', 'sets': 3, 'reps': '10', 'load': '60 kg', 'restSeconds': 90, 'technique': 'Pausa 1 s arriba', 'notes': null},
              {'name': 'Extensión de pierna', 'sets': 3, 'reps': '15', 'load': null, 'restSeconds': 60, 'technique': 'Drop set en la última', 'notes': null},
            ],
            'notes': null,
          },
          {
            'name': 'Día 2 · Empuje',
            'focus': 'Pecho, hombro y tríceps',
            'exercises': [
              {'name': 'Press de banca', 'sets': 4, 'reps': '6-8', 'load': 'RPE 8', 'restSeconds': 120, 'technique': null, 'notes': null},
              {'name': 'Press inclinado con mancuernas', 'sets': 3, 'reps': '10', 'load': null, 'restSeconds': 90, 'technique': null, 'notes': null},
              {'name': 'Elevaciones laterales', 'sets': 4, 'reps': '15', 'load': null, 'restSeconds': 45, 'technique': null, 'notes': null},
            ],
            'notes': null,
          },
          {
            'name': 'Día 3 · Tracción',
            'focus': 'Espalda y bíceps',
            'exercises': [
              {'name': 'Peso muerto rumano', 'sets': 4, 'reps': '8', 'load': 'RPE 7', 'restSeconds': 120, 'technique': null, 'notes': null},
              {'name': 'Jalón al pecho', 'sets': 3, 'reps': '10-12', 'load': null, 'restSeconds': 90, 'technique': null, 'notes': null},
              {'name': 'Remo con mancuerna', 'sets': 3, 'reps': '12', 'load': null, 'restSeconds': 60, 'technique': null, 'notes': null},
            ],
            'notes': null,
          },
        ],
        'generalNotes': 'Sube 2.5 kg cuando completes todas las series en el rango alto.',
        'confidence': 'alta',
        'warnings': <String>[],
      };

  static Map<String, dynamic> get dietPlanContent => {
        'title': 'Plan de alimentación · Definición',
        'summary': 'Cinco comidas, ~1,800 kcal, alto en proteína.',
        'meals': [
          {
            'name': 'Desayuno',
            'time': '7:30',
            'items': [
              {'food': 'Claras de huevo', 'quantity': '4 piezas', 'notes': null},
              {'food': 'Avena', 'quantity': '40 g', 'notes': 'en agua o leche light'},
              {'food': 'Plátano', 'quantity': '1 pieza', 'notes': null},
            ],
            'notes': null,
          },
          {
            'name': 'Colación 1',
            'time': '11:00',
            'items': [
              {'food': 'Yogur griego natural', 'quantity': '150 g', 'notes': null},
              {'food': 'Nuez', 'quantity': '10 g', 'notes': null},
            ],
            'notes': null,
          },
          {
            'name': 'Comida',
            'time': '14:30',
            'items': [
              {'food': 'Pechuga de pollo', 'quantity': '150 g', 'notes': null},
              {'food': 'Arroz cocido', 'quantity': '1 taza', 'notes': null},
              {'food': 'Verduras al vapor', 'quantity': 'libre', 'notes': null},
            ],
            'notes': null,
          },
          {
            'name': 'Cena',
            'time': '20:00',
            'items': [
              {'food': 'Salmón o atún', 'quantity': '120 g', 'notes': null},
              {'food': 'Ensalada', 'quantity': 'libre', 'notes': '1 cda de aceite de oliva'},
            ],
            'notes': null,
          },
        ],
        'substitutions': [
          'Pollo 150 g = pescado blanco 170 g = carne magra 130 g',
          'Arroz 1 taza = papa 200 g = tortilla de maíz 2 piezas',
        ],
        'generalNotes': 'Agua: 2.5 L al día. Evitar bebidas azucaradas.',
        'confidence': 'media',
        'warnings': [
          'La cantidad de aguacate en la comida estaba borrosa en el PDF; se omitió.',
        ],
      };

  static List<PlanEntity> get plans => [
        PlanEntity(
          id: 'plan-u0-ent',
          coachId: coachId,
          userId: 'u0',
          kind: PlanKind.entrenamiento,
          title: 'Fuerza · Bloque 1 (4 semanas)',
          currentVersion: 2,
          content: workoutPlanContent,
          sourceDocumentId: 'doc-u0-ent',
          publishedAt: _daysAgo(3),
          publishedBy: uid,
        ),
        PlanEntity(
          id: 'plan-u0-dieta',
          coachId: coachId,
          userId: 'u0',
          kind: PlanKind.dieta,
          title: 'Plan de alimentación · Definición',
          currentVersion: 1,
          content: dietPlanContent,
          sourceDocumentId: 'doc-u0-dieta',
          publishedAt: _daysAgo(10),
          publishedBy: uid,
        ),
        PlanEntity(
          id: 'plan-coach-ent',
          coachId: coachId,
          userId: uid,
          kind: PlanKind.entrenamiento,
          title: 'Fuerza · Bloque 1 (4 semanas)',
          currentVersion: 1,
          content: workoutPlanContent,
          sourceDocumentId: null,
          publishedAt: _daysAgo(1),
          publishedBy: uid,
        ),
        PlanEntity(
          id: 'plan-coach-dieta',
          coachId: coachId,
          userId: uid,
          kind: PlanKind.dieta,
          title: 'Plan de alimentación · Definición',
          currentVersion: 1,
          content: dietPlanContent,
          sourceDocumentId: null,
          publishedAt: _daysAgo(4),
          publishedBy: uid,
        ),
      ];

  // --- Sesiones y comidas ----------------------------------------------------

  /// Sessão concluída anteontem: faz o planejador oferecer o "Día 2" como
  /// próximo treino e alimenta o pré-preenchimento de cargas.
  static WorkoutSessionEntity get lastSession => WorkoutSessionEntity(
        id: 'sess-1',
        userId: uid,
        coachId: coachId,
        planId: 'plan-coach-ent',
        planVersion: 1,
        dayIndex: 0,
        dayName: 'Día 1 · Pierna',
        status: SessionStatus.completada,
        startedAt: _daysAgo(2),
        finishedAt: _daysAgo(2).add(const Duration(minutes: 58)),
        durationSec: 58 * 60,
        totalVolumeKg: 5240,
        validated: true,
        countedForStreak: true,
        xpGranted: AppConstants.xpWorkoutLogged,
        exercises: [
          SessionExercise(
            name: 'Sentadilla con barra',
            targetSets: 4,
            targetReps: '6-8',
            targetLoad: 'RPE 8',
            restSeconds: 120,
            sets: [
              for (var i = 0; i < 4; i++)
                SessionSet(reps: 8, load: 70, done: true),
            ],
          ),
          SessionExercise(
            name: 'Prensa 45°',
            targetSets: 3,
            targetReps: '10-12',
            restSeconds: 90,
            sets: [
              for (var i = 0; i < 3; i++)
                SessionSet(reps: 12, load: 120, done: true),
            ],
          ),
        ],
      );

  static List<WorkoutSessionEntity> get sessions => [lastSession];

  static List<MealLogEntity> get todayMealLogs {
    final date = MealLogEntity.dateKey(DateTime.now());
    return [
      MealLogEntity(
        id: MealLogEntity.idFor(uid, date, 0),
        userId: uid,
        coachId: coachId,
        planId: 'plan-coach-dieta',
        date: date,
        mealIndex: 0,
        mealName: 'Desayuno',
        status: MealStatus.hecha,
        createdAt: _hoursAgo(6),
      ),
      MealLogEntity(
        id: MealLogEntity.idFor(uid, date, 1),
        userId: uid,
        coachId: coachId,
        planId: 'plan-coach-dieta',
        date: date,
        mealIndex: 1,
        mealName: 'Colación 1',
        status: MealStatus.cambiada,
        createdAt: _hoursAgo(2),
      ),
    ];
  }

  static PlanDocumentEntity _document({
    required String id,
    required String userId,
    required PlanKind kind,
    required String fileName,
    required PlanDocumentStatus status,
    Map<String, dynamic>? parsedPlan,
    String? errorMessage,
    int hoursAgo = 2,
  }) =>
      PlanDocumentEntity(
        id: id,
        coachId: coachId,
        userId: userId,
        uploadedBy: uid,
        kind: kind,
        fileName: fileName,
        storagePath: 'documents/$coachId/$userId/$fileName',
        downloadUrl: null,
        contentType: fileName.endsWith('.pdf')
            ? 'application/pdf'
            : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        sizeBytes: 250000,
        status: status,
        errorMessage: errorMessage,
        parsedPlan: parsedPlan,
        planId: null,
        createdAt: _hoursAgo(hoursAgo),
        updatedAt: _hoursAgo(hoursAgo),
      );

  static List<PlanDocumentEntity> get documents => [
        _document(
          id: 'doc-u1-dieta',
          userId: 'u1',
          kind: PlanKind.dieta,
          fileName: 'Plan_Fernanda_sep.pdf',
          status: PlanDocumentStatus.listo,
          parsedPlan: dietPlanContent,
          hoursAgo: 1,
        ),
        _document(
          id: 'doc-u2-ent',
          userId: 'u2',
          kind: PlanKind.entrenamiento,
          fileName: 'Rutina_Diego.docx',
          status: PlanDocumentStatus.procesando,
        ),
        _document(
          id: 'doc-u3-macros',
          userId: 'u3',
          kind: PlanKind.macros,
          fileName: 'macros_rafa.pdf',
          status: PlanDocumentStatus.error,
          errorMessage: 'El PDF está protegido con contraseña.',
          hoursAgo: 5,
        ),
        _document(
          id: 'doc-u0-ent',
          userId: 'u0',
          kind: PlanKind.entrenamiento,
          fileName: 'Bloque1_Carlos.pdf',
          status: PlanDocumentStatus.publicado,
          parsedPlan: workoutPlanContent,
          hoursAgo: 72,
        ),
      ];

  static List<ShareEventEntity> get shares => [
        ShareEventEntity(
          id: 's1',
          userId: 'u0',
          userName: 'Carlos Núñez',
          kind: ShareCardKind.record,
          sharedAt: _hoursAgo(4),
        ),
        ShareEventEntity(
          id: 's2',
          userId: 'u1',
          userName: 'Fernanda Ríos',
          kind: ShareCardKind.racha,
          sharedAt: _hoursAgo(20),
        ),
        ShareEventEntity(
          id: 's3',
          userId: 'u4',
          userName: 'Ximena Castro',
          kind: ShareCardKind.entrenamiento,
          sharedAt: _daysAgo(2),
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
