import 'package:flutter_test/flutter_test.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/features/challenges/data/repositories/firestore_challenge_repository.dart';
import 'package:gymrank/features/challenges/domain/entities/challenge_entity.dart';

/// Quem vê qual reto. A aba Retos lê todos os ativos e separa aqui; a
/// separação tem de aceitar tanto `coachId: null` quanto o campo ausente
/// (os dois viram `null` na entidade), porque os retos globais são
/// criados à mão no console.
void main() {
  ChallengeEntity reto(String? coachId) => ChallengeEntity(
        id: 'r-${coachId ?? 'global'}',
        coachId: coachId,
        title: 't',
        description: 'd',
        scope: ChallengeScope.comunidad,
        period: ChallengePeriod.semanal,
        metric: ChallengeMetric.diasTreinados,
        targetValue: 3,
        startsAt: DateTime(2026),
        endsAt: DateTime(2026, 2),
        xpReward: 10,
        rewardId: null,
        participantCount: 0,
        isActive: true,
        createdAt: DateTime(2026),
      );

  test('aluna da comunidade vê os da sua treinadora e os globais', () {
    expect(FirestoreChallengeRepository.isVisibleTo(reto('coach-1'), coachId: 'coach-1'), isTrue);
    expect(FirestoreChallengeRepository.isVisibleTo(reto(null), coachId: 'coach-1'), isTrue);
  });

  test('não vê os retos de outra treinadora', () {
    expect(FirestoreChallengeRepository.isVisibleTo(reto('coach-2'), coachId: 'coach-1'), isFalse);
  });

  test('aluna ainda sem treinadora vê só os globais', () {
    expect(FirestoreChallengeRepository.isVisibleTo(reto(null), coachId: null), isTrue);
    expect(FirestoreChallengeRepository.isVisibleTo(reto('coach-1'), coachId: null), isFalse);
  });
}
