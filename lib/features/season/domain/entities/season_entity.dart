import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gymrank/core/constants/app_constants.dart';

part 'season_entity.freezed.dart';

/// Documento canônico de `seasons/{seasonId}`. Ao final da temporada, uma
/// Cloud Function agendada (`seasonReset`) zera `xpCurrentSeason` e o
/// Gym Score de ranking de todos os usuários, preservando os totais
/// históricos, e concede badges permanentes ao Top 3 / Top 10.
@freezed
class SeasonEntity with _$SeasonEntity {
  const factory SeasonEntity({
    required String id,

    /// `null` = temporada global da plataforma.
    required String? coachId,
    required int number,
    required SeasonDuration duration,
    required DateTime startsAt,
    required DateTime endsAt,
    required bool isActive,
    required bool rewardsDistributed,
  }) = _SeasonEntity;
}

/// Documento canônico de `seasons/{seasonId}/results/{userId}`: posição
/// final imutável de um usuário ao término da temporada.
@freezed
class SeasonResultEntity with _$SeasonResultEntity {
  const factory SeasonResultEntity({
    required String userId,
    required String seasonId,
    required int finalPosition,
    required int xpEarned,
    required double finalGymScore,
    required bool badgeGranted,
  }) = _SeasonResultEntity;
}
