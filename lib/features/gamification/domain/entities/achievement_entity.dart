import 'package:freezed_annotation/freezed_annotation.dart';

part 'achievement_entity.freezed.dart';

enum AchievementCode {
  primeiroTreino,
  sequencia7Dias,
  sequencia30Dias,
  sequencia100Dias,
  sequencia365Dias,
  primeiraFoto,
  primeiroAmigo,
  primeiroDesafio,
  top10,
  top3,
  top1,
}

/// Catálogo estático de conquistas disponíveis (`achievement_catalog/{code}`).
@freezed
class AchievementDefinition with _$AchievementDefinition {
  const factory AchievementDefinition({
    required AchievementCode code,
    required String title,
    required String description,
    required String iconAsset,
  }) = _AchievementDefinition;
}

/// Documento canônico de `users/{uid}/achievements/{code}`: registro
/// imutável de quando o usuário desbloqueou a conquista.
@freezed
class UserAchievementEntity with _$UserAchievementEntity {
  const factory UserAchievementEntity({
    required AchievementCode code,
    required DateTime unlockedAt,
  }) = _UserAchievementEntity;
}
