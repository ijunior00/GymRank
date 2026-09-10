import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/challenges/domain/entities/challenge_entity.dart';

abstract interface class ChallengeRepository {
  /// Desafios ativos da comunidade da treinadora ([coachId]) mais os
  /// globais (`coachId == null`).
  Stream<List<ChallengeEntity>> watchActive({String? coachId});

  Future<Result<void>> join({
    required String challengeId,
    required String userId,
  });

  Stream<ChallengeParticipantEntity?> watchParticipation({
    required String challengeId,
    required String userId,
  });
}
