import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/challenges/domain/entities/challenge_entity.dart';

abstract interface class ChallengeRepository {
  /// Desafios ativos da comunidade da treinadora ([coachId]) mais os
  /// globais (`coachId == null`).
  Stream<List<ChallengeEntity>> watchActive({String? coachId});

  /// Todos os retos da comunidade, ativos e encerrados, mais recentes
  /// primeiro. Visão da treinadora.
  Stream<List<ChallengeEntity>> watchByCoach(String coachId);

  Stream<ChallengeEntity?> watchChallenge(String challengeId);

  /// Cria (id vazio) ou atualiza um reto. Só a treinadora da comunidade;
  /// as regras do Firestore validam os limites (XP entre 10 e 1000, meta
  /// positiva, fim depois do início, prêmio da própria comunidade).
  /// `participantCount` e `createdAt` são do servidor.
  Future<Result<ChallengeEntity>> save(ChallengeEntity challenge);

  /// Encerra (ou reabre) um reto sem apagar o histórico das inscritas.
  Future<Result<void>> setActive({
    required String challengeId,
    required bool active,
  });

  Future<Result<void>> join({
    required String challengeId,
    required String userId,
  });

  Stream<ChallengeParticipantEntity?> watchParticipation({
    required String challengeId,
    required String userId,
  });

  /// Inscritas de um reto, maior progresso primeiro. Visão da treinadora.
  Stream<List<ChallengeParticipantEntity>> watchParticipants(String challengeId);
}
