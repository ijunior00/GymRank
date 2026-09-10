import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gymrank/core/constants/app_constants.dart';

part 'user_entity.freezed.dart';

/// Documento canônico de `users/{uid}`. Ver docs/firestore-schema.md#users.
@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String name,
    required String username,
    required String? photoUrl,
    required DateTime birthDate,
    required String sex,
    required double heightCm,
    required String city,

    /// Para o aluno: a treinadora que o acompanha (`coaches/{coachId}`).
    /// Para a treinadora/nutrióloga: o próprio painel. `null` sem vínculo.
    required String? coachId,
    required UserGoal goal,
    required UserRole role,
    required int level,
    required int xpTotal,
    required int xpCurrentSeason,
    required double gymScore,
    required int currentStreakDays,
    required int longestStreakDays,
    required DateTime? lastCheckInAt,
    required SubscriptionPlan plan,

    /// `username` de quem convidou este aluno, informado no cadastro.
    /// Imutável depois de criado (ver firestore.rules).
    required String? referredBy,

    /// **[CF]** quantos alunos entraram indicados por este usuário.
    required int referralCount,
    required DateTime createdAt,
  }) = _UserEntity;

  const UserEntity._();

  bool get isCoach => role == UserRole.coach;

  bool get isNutriologo => role == UserRole.nutriologo;

  /// Quem tem acesso ao painel da comunidade (treinadora, nutrióloga ou
  /// administração da plataforma).
  bool get isStaff =>
      role == UserRole.coach ||
      role == UserRole.nutriologo ||
      role == UserRole.adminGlobal;

  bool get isPremium => plan == SubscriptionPlan.premium;
}
