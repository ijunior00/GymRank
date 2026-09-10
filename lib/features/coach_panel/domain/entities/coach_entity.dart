import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gymrank/core/constants/app_constants.dart';

part 'coach_entity.freezed.dart';

/// Documento canônico de `coaches/{coachId}`: a treinadora dona da conta,
/// sua marca e as configurações da comunidade dela. Substitui a antiga
/// coleção `gyms` do modelo B2B2C (ver docs/firestore-schema.md#coaches).
@freezed
class CoachEntity with _$CoachEntity {
  const factory CoachEntity({
    required String id,

    /// `users/{uid}` da treinadora. É quem administra o painel.
    required String ownerUserId,

    /// Nome da marca/método exibido aos alunos (ex.: "Método VF").
    required String name,
    required String? tagline,
    required String city,
    required String country,
    required String? logoUrl,
    required String? brandColorHex,
    required String? instagramHandle,

    /// Código curto que o aluno digita para se vincular à treinadora.
    required String inviteCode,

    /// Segredo do QR Code de check-in presencial (HMAC). Só é usado se a
    /// treinadora atender presencialmente; alunos online usam a conclusão
    /// do treino como check-in.
    required String qrCodeSecret,
    required SubscriptionPlan plan,
    required int studentCount,
    required int activeChallengeCount,
    required DateTime createdAt,
  }) = _CoachEntity;
}

/// Estatísticas agregadas do painel da coach (calculadas pela Cloud
/// Function `recalculateCoachDashboard` e armazenadas em
/// `coaches/{coachId}/stats/current`).
@freezed
class CoachDashboardStats with _$CoachDashboardStats {
  const factory CoachDashboardStats({
    required int totalStudents,
    required int activeStudents,
    required int workoutsToday,
    required int workoutsThisWeek,
    required int newStudentsThisMonth,
    required int inactiveStudents7d,
    required double retentionRate,
    required DateTime calculatedAt,
  }) = _CoachDashboardStats;
}
