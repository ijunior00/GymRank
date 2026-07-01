/// Constantes globais de negócio. Valores balanceáveis (XP, pesos do Gym
/// Score) também existem no Remote Config para ajuste sem deploy; estes
/// são os defaults usados quando o Remote Config ainda não foi buscado.
abstract final class AppConstants {
  // XP por ação (ver docs/firestore-schema.md#xp)
  static const int xpCheckIn = 20;
  static const int xpWorkoutLogged = 50;
  static const int xpBodyMeasurement = 30;
  static const int xpProgressPhoto = 25;
  static const int xpChallengeCompleted = 200;
  static const int xpFriendInvited = 150;

  // Pesos do Gym Score (somam 1.0)
  static const double gymScoreWeightFrequency = 0.35;
  static const double gymScoreWeightConsistency = 0.25;
  static const double gymScoreWeightChallenges = 0.20;
  static const double gymScoreWeightEvolution = 0.20;

  // Paginação
  static const int defaultPageSize = 20;
  static const int feedPageSize = 15;

  // Check-in
  static const Duration checkInCooldown = Duration(hours: 6);
  static const Duration qrCodeTokenTtl = Duration(seconds: 30);
}

enum UserGoal { emagrecimento, hipertrofia, performance, saude, reabilitacao }

enum UserRole { aluno, personal, academia, adminGlobal }

enum ChallengeScope { individual, equipe, academia, regional }

enum ChallengePeriod { semanal, mensal }

enum SeasonDuration { mensal, trimestral }

enum MeasurementType {
  peso,
  percentualGordura,
  massaMuscular,
  imc,
  braco,
  peitoral,
  cintura,
  abdomen,
  quadril,
  coxa,
  panturrilha,
}

enum ProgressPhotoCategory { frente, costas, perfil }

enum SubscriptionPlan { free, premium }
