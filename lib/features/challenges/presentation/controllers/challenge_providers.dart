import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/challenges/data/repositories/firestore_challenge_repository.dart';
import 'package:gymrank/features/challenges/domain/entities/challenge_entity.dart';
import 'package:gymrank/features/challenges/domain/repositories/challenge_repository.dart';

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return FirestoreChallengeRepository(ref.watch(firestoreProvider));
});

final activeChallengesProvider = StreamProvider<List<ChallengeEntity>>((ref) {
  final coachId = ref.watch(currentUserProvider).valueOrNull?.coachId;
  return ref.watch(challengeRepositoryProvider).watchActive(coachId: coachId);
});

/// Inscrição do usuário logado num reto: `null` = ainda não entrou.
final challengeParticipationProvider =
    StreamProvider.family<ChallengeParticipantEntity?, String>(
        (ref, challengeId) {
  final uid = ref.watch(authStateProvider).valueOrNull;
  if (uid == null) return Stream.value(null);
  return ref.watch(challengeRepositoryProvider).watchParticipation(
        challengeId: challengeId,
        userId: uid,
      );
});

/// Todos os retos da comunidade da treinadora logada (ativos e
/// encerrados), mais recentes primeiro.
final coachChallengesProvider = StreamProvider<List<ChallengeEntity>>((ref) {
  final coachId = ref.watch(currentUserProvider).valueOrNull?.coachId;
  if (coachId == null) return Stream.value(const []);
  return ref.watch(challengeRepositoryProvider).watchByCoach(coachId);
});

final challengeByIdProvider =
    StreamProvider.family<ChallengeEntity?, String>((ref, challengeId) {
  return ref.watch(challengeRepositoryProvider).watchChallenge(challengeId);
});

/// Inscritas de um reto, maior progresso primeiro (visão da treinadora).
final challengeParticipantsProvider =
    StreamProvider.family<List<ChallengeParticipantEntity>, String>(
        (ref, challengeId) {
  return ref.watch(challengeRepositoryProvider).watchParticipants(challengeId);
});
