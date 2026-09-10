import 'package:freezed_annotation/freezed_annotation.dart';

part 'championship_entity.freezed.dart';

enum ChampionshipCriteria { maisXp, maiorGymScore, maisCheckIns, maiorEvolucao }

/// Documento canônico de `championships/{championshipId}`. Diferente de
/// [ChallengeEntity], torneios são criados exclusivamente pela treinadora
/// para a comunidade dela e sempre geram um ranking automático com
/// premiação.
@freezed
class ChampionshipEntity with _$ChampionshipEntity {
  const factory ChampionshipEntity({
    required String id,
    required String coachId,
    required String name,
    required String description,
    required DateTime startsAt,
    required DateTime endsAt,
    required ChampionshipCriteria criteria,
    required List<String> rewardIds,
    required int participantCount,
    required bool isFinished,
    required DateTime createdAt,
  }) = _ChampionshipEntity;
}
