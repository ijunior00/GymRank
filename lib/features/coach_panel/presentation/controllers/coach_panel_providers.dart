import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/body_measurement/domain/entities/body_measurement_entity.dart';
import 'package:gymrank/features/body_measurement/presentation/controllers/body_measurement_providers.dart';
import 'package:gymrank/features/coach_panel/data/repositories/firestore_coach_panel_repository.dart';
import 'package:gymrank/features/coach_panel/domain/entities/client_entity.dart';
import 'package:gymrank/features/coach_panel/domain/entities/coach_entity.dart';
import 'package:gymrank/features/coach_panel/domain/repositories/coach_panel_repository.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';
import 'package:gymrank/features/profile/presentation/controllers/user_repository_provider.dart';
import 'package:gymrank/features/workout/domain/entities/workout_entity.dart';
import 'package:gymrank/features/workout/presentation/controllers/workout_providers.dart';

final coachPanelRepositoryProvider = Provider<CoachPanelRepository>((ref) {
  return FirestoreCoachPanelRepository(ref.watch(firestoreProvider));
});

/// `coachId` do usuário logado: para a treinadora é o próprio painel; para
/// o aluno é quem o acompanha. `null` enquanto não há vínculo.
final currentCoachIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider).valueOrNull?.coachId;
});

final currentCoachProvider = StreamProvider<CoachEntity?>((ref) {
  final coachId = ref.watch(currentCoachIdProvider);
  if (coachId == null) return Stream.value(null);
  return ref.watch(coachPanelRepositoryProvider).watchCoach(coachId);
});

final coachDashboardStatsProvider =
    StreamProvider<CoachDashboardStats?>((ref) {
  final coachId = ref.watch(currentCoachIdProvider);
  if (coachId == null) return Stream.value(null);
  return ref.watch(coachPanelRepositoryProvider).watchDashboardStats(coachId);
});

final coachStudentUsersProvider = StreamProvider<List<UserEntity>>((ref) {
  final coachId = ref.watch(currentCoachIdProvider);
  if (coachId == null) return Stream.value(const []);
  return ref.watch(coachPanelRepositoryProvider).watchStudents(coachId);
});

final coachClientsProvider = StreamProvider<List<ClientEntity>>((ref) {
  final coachId = ref.watch(currentCoachIdProvider);
  if (coachId == null) return Stream.value(const []);
  return ref.watch(coachPanelRepositoryProvider).watchClients(coachId);
});

/// Junta `users` (perfil público) com `clients` (vínculo) por `userId`.
/// Combinação feita aqui, e não no repositório, para não exigir uma
/// dependência de stream-zip: os dois StreamProviders acima já são
/// reativos e o Provider é reavaliado quando qualquer um emite.
final coachStudentsProvider =
    Provider<AsyncValue<List<CoachStudentView>>>((ref) {
  final users = ref.watch(coachStudentUsersProvider);
  final clients = ref.watch(coachClientsProvider);

  final error = users.error ?? clients.error;
  if (error != null) {
    return AsyncValue.error(
      error,
      users.stackTrace ?? clients.stackTrace ?? StackTrace.current,
    );
  }
  if (!users.hasValue || !clients.hasValue) {
    return const AsyncValue.loading();
  }

  final clientById = {for (final c in clients.value!) c.userId: c};
  final list = [
    for (final u in users.value!)
      CoachStudentView(user: u, client: clientById[u.id]),
  ]..sort((a, b) => a.user.name.toLowerCase().compareTo(b.user.name.toLowerCase()));
  return AsyncValue.data(list);
});

final studentUserProvider =
    StreamProvider.family<UserEntity?, String>((ref, userId) {
  return ref
      .watch(userRepositoryProvider)
      .watch(userId)
      .map((result) => result.dataOrNull);
});

final clientDetailProvider =
    StreamProvider.family<ClientEntity?, String>((ref, userId) {
  final coachId = ref.watch(currentCoachIdProvider);
  if (coachId == null) return Stream.value(null);
  return ref
      .watch(coachPanelRepositoryProvider)
      .watchClient(coachId: coachId, userId: userId);
});

final clientNotesProvider =
    StreamProvider.family<List<CoachNoteEntity>, String>((ref, userId) {
  final coachId = ref.watch(currentCoachIdProvider);
  if (coachId == null) return Stream.value(const []);
  return ref
      .watch(coachPanelRepositoryProvider)
      .watchNotes(coachId: coachId, userId: userId);
});

final studentMeasurementsProvider =
    StreamProvider.family<List<BodyMeasurementEntity>, String>((ref, userId) {
  return ref.watch(bodyMeasurementRepositoryProvider).watchHistory(userId);
});

final studentWorkoutsProvider =
    StreamProvider.family<List<WorkoutEntity>, String>((ref, userId) {
  return ref.watch(workoutRepositoryProvider).watchRecent(userId, limit: 10);
});

/// O vínculo do aluno logado com a treinadora dele (plano, próximo pago).
/// É o que o perfil mostra em "Mi plan con …". `null` para a própria
/// treinadora e para quem ainda não entrou numa comunidade.
final myClientProvider = StreamProvider<ClientEntity?>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  final coachId = user?.coachId;
  if (user == null || coachId == null || user.isStaff) {
    return Stream.value(null);
  }
  return ref
      .watch(coachPanelRepositoryProvider)
      .watchClient(coachId: coachId, userId: user.id);
});
