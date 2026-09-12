import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/features/challenges/domain/entities/challenge_entity.dart';
import 'package:gymrank/features/championships/domain/entities/championship_entity.dart';
import 'package:gymrank/features/coach_panel/domain/entities/client_entity.dart';
import 'package:gymrank/features/friendship/domain/entities/friendship_entity.dart';
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';
import 'package:gymrank/features/rankings/domain/entities/ranking_entry_entity.dart';
import 'package:gymrank/features/rewards/domain/entities/reward_entity.dart';
import 'package:gymrank/features/workout/domain/entities/workout_entity.dart';

/// Rótulos em espanhol (México) para os enums de domínio compartilhados
/// entre telas. Os identificadores dos enums continuam sendo os nomes
/// persistidos no Firestore; só o texto exibido muda.
///
/// Enums usados por uma única tela podem manter uma extensão de rótulo
/// privada à própria tela (ex.: `ProgressPhotoCategory`).
extension UserGoalLabelEs on UserGoal {
  String get labelEs => switch (this) {
        UserGoal.emagrecimento => 'Bajar de peso',
        UserGoal.hipertrofia => 'Ganar músculo',
        UserGoal.performance => 'Rendimiento',
        UserGoal.saude => 'Salud',
        UserGoal.reabilitacao => 'Rehabilitación',
      };
}

extension UserRoleLabelEs on UserRole {
  String get labelEs => switch (this) {
        UserRole.alumno => 'Alumno',
        UserRole.coach => 'Coach',
        UserRole.nutriologo => 'Nutrióloga',
        UserRole.adminGlobal => 'Administrador',
      };
}

extension RankingScopeLabelEs on RankingScope {
  String get labelEs => switch (this) {
        RankingScope.comunidad => 'Mi comunidad',
        RankingScope.amigos => 'Amigos',
        RankingScope.ciudad => 'Ciudad',
        RankingScope.nacional => 'Nacional',
      };
}

extension RankingCriteriaLabelEs on RankingCriteria {
  String get labelEs => switch (this) {
        RankingCriteria.consistencia => 'Constancia',
        RankingCriteria.evolucao => 'Progreso',
        RankingCriteria.xp => 'XP',
        RankingCriteria.gymScore => 'Gym Score',
      };
}

extension ChallengeScopeLabelEs on ChallengeScope {
  String get labelEs => switch (this) {
        ChallengeScope.individual => 'Individual',
        ChallengeScope.equipo => 'Por equipos',
        ChallengeScope.comunidad => 'Comunidad',
        ChallengeScope.regional => 'Regional',
      };
}

extension ChallengePeriodLabelEs on ChallengePeriod {
  String get labelEs => switch (this) {
        ChallengePeriod.semanal => 'Semanal',
        ChallengePeriod.mensal => 'Mensual',
      };
}

extension ChallengeMetricLabelEs on ChallengeMetric {
  String get labelEs => switch (this) {
        ChallengeMetric.diasTreinados => 'Días entrenados',
        ChallengeMetric.distanciaKm => 'Kilómetros',
        ChallengeMetric.pesoPerdidoKg => 'Kilos perdidos',
        ChallengeMetric.massaMuscularGanhaKg => 'Masa muscular ganada',
        ChallengeMetric.checkIns => 'Check-ins',
      };
}

extension ClientStatusLabelEs on ClientStatus {
  String get labelEs => switch (this) {
        ClientStatus.activo => 'Activo',
        ClientStatus.pausado => 'En pausa',
        ClientStatus.inactivo => 'Inactivo',
      };
}

extension StudentActivityLabelEs on StudentActivity {
  String get labelEs => switch (this) {
        StudentActivity.alDia => 'Al día',
        StudentActivity.enRiesgo => 'En riesgo',
        StudentActivity.sinActividad => 'Sin actividad',
        StudentActivity.sinRegistros => 'Sin registros',
      };
}

extension MuscleGroupLabelEs on MuscleGroup {
  String get labelEs => switch (this) {
        MuscleGroup.peito => 'Pecho',
        MuscleGroup.costas => 'Espalda',
        MuscleGroup.pernas => 'Piernas',
        MuscleGroup.ombro => 'Hombro',
        MuscleGroup.biceps => 'Bíceps',
        MuscleGroup.triceps => 'Tríceps',
        MuscleGroup.abdomen => 'Abdomen',
        MuscleGroup.cardio => 'Cardio',
        MuscleGroup.corpoInteiro => 'Cuerpo completo',
      };
}

extension WorkoutIntensityLabelEs on WorkoutIntensity {
  String get labelEs => switch (this) {
        WorkoutIntensity.leve => 'Ligera',
        WorkoutIntensity.moderada => 'Moderada',
        WorkoutIntensity.intensa => 'Intensa',
      };
}

extension FriendshipStatusLabelEs on FriendshipStatus {
  String get labelEs => switch (this) {
        FriendshipStatus.pending => 'Pendiente',
        FriendshipStatus.accepted => 'Amigos',
        FriendshipStatus.blocked => 'Bloqueado',
      };
}

extension RewardStatusLabelEs on RewardStatus {
  String get labelEs => switch (this) {
        RewardStatus.available => 'Disponible',
        RewardStatus.granted => 'Otorgado',
        RewardStatus.redeemed => 'Canjeado',
        RewardStatus.expired => 'Vencido',
      };
}

extension PlanKindLabelEs on PlanKind {
  String get labelEs => switch (this) {
        PlanKind.entrenamiento => 'Entrenamiento',
        PlanKind.dieta => 'Alimentación',
        PlanKind.macros => 'Macros',
        PlanKind.evaluacion => 'Evaluación',
        PlanKind.otro => 'Otro documento',
      };
}

extension PlanDocumentStatusLabelEs on PlanDocumentStatus {
  String get labelEs => switch (this) {
        PlanDocumentStatus.subido => 'En cola',
        PlanDocumentStatus.procesando => 'Leyendo…',
        PlanDocumentStatus.listo => 'Listo para revisar',
        PlanDocumentStatus.error => 'Error',
        PlanDocumentStatus.publicado => 'Publicado',
      };
}

extension RewardTypeLabelEs on RewardType {
  String get labelEs => switch (this) {
        RewardType.suplemento => 'Suplemento',
        RewardType.vestuario => 'Ropa',
        RewardType.consultoria => 'Asesoría',
        RewardType.mensalidadeGratis => 'Mensualidad gratis',
        RewardType.acessorio => 'Accesorio',
        RewardType.valeCompras => 'Vale de compras',
      };
}

extension ChampionshipCriteriaLabelEs on ChampionshipCriteria {
  String get labelEs => switch (this) {
        ChampionshipCriteria.maisXp => 'Más XP',
        ChampionshipCriteria.maiorGymScore => 'Mayor Gym Score',
        ChampionshipCriteria.maisCheckIns => 'Más check-ins',
        ChampionshipCriteria.maiorEvolucao => 'Mayor evolución',
      };
}

/// `sourceType` de `rewards/{id}/grants` (string livre no backend).
String rewardSourceLabelEs(String sourceType) => switch (sourceType) {
      'challenge' => 'reto',
      'championship' => 'torneo',
      'season' => 'temporada',
      _ => sourceType,
    };
