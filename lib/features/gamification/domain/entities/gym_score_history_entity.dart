import 'package:freezed_annotation/freezed_annotation.dart';

part 'gym_score_history_entity.freezed.dart';

/// Documento canônico de `gym_score_history/{entryId}`, gerado
/// periodicamente pela Cloud Function `recalculateGymScore`. Histórico
/// imutável usado para gráficos de evolução do Gym Score.
@freezed
class GymScoreHistoryEntity with _$GymScoreHistoryEntity {
  const factory GymScoreHistoryEntity({
    required String id,
    required String userId,
    required DateTime calculatedAt,
    required double frequencyScore,
    required double consistencyScore,
    required double challengesScore,
    required double evolutionScore,
    required double totalScore,
    required String? seasonId,
  }) = _GymScoreHistoryEntity;
}
