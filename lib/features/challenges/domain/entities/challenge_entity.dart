import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gymrank/core/constants/app_constants.dart';

part 'challenge_entity.freezed.dart';

enum ChallengeMetric {
  diasTreinados,
  distanciaKm,
  pesoPerdidoKg,
  massaMuscularGanhaKg,
  checkIns,
}

/// Documento canônico de `challenges/{challengeId}`. `coachId` nulo =
/// desafio global da plataforma, aberto a qualquer comunidade.
@freezed
class ChallengeEntity with _$ChallengeEntity {
  const factory ChallengeEntity({
    required String id,
    required String? coachId,
    required String title,
    required String description,
    required ChallengeScope scope,
    required ChallengePeriod period,
    required ChallengeMetric metric,
    required double targetValue,
    required DateTime startsAt,
    required DateTime endsAt,
    required int xpReward,
    String? rewardId,
    required int participantCount,
    required bool isActive,
    required DateTime createdAt,
  }) = _ChallengeEntity;
}

/// Documento canônico de `challenges/{challengeId}/participants/{userId}`.
@freezed
class ChallengeParticipantEntity with _$ChallengeParticipantEntity {
  const factory ChallengeParticipantEntity({
    required String userId,
    required String challengeId,
    required double currentValue,
    required bool completed,
    DateTime? completedAt,
  }) = _ChallengeParticipantEntity;
}
