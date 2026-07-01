import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/challenges/domain/entities/challenge_entity.dart';

abstract interface class ChallengeRepository {
  Stream<List<ChallengeEntity>> watchActive({String? gymId});

  Future<Result<void>> join({
    required String challengeId,
    required String userId,
  });

  Stream<ChallengeParticipantEntity?> watchParticipation({
    required String challengeId,
    required String userId,
  });
}
