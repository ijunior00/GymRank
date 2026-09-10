import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/championships/data/repositories/firestore_championship_repository.dart';
import 'package:gymrank/features/championships/domain/entities/championship_entity.dart';
import 'package:gymrank/features/championships/domain/repositories/championship_repository.dart';

final championshipRepositoryProvider = Provider<ChampionshipRepository>((ref) {
  return FirestoreChampionshipRepository(ref.watch(firestoreProvider));
});

/// Torneios da comunidade da treinadora do usuário logado.
final communityChampionshipsProvider =
    StreamProvider<List<ChampionshipEntity>>((ref) {
  final coachId = ref.watch(currentUserProvider).valueOrNull?.coachId;
  if (coachId == null) return Stream.value(const []);
  return ref.watch(championshipRepositoryProvider).watchByCoach(coachId);
});
