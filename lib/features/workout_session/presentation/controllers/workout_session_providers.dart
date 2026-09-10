import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/plans/presentation/controllers/plan_providers.dart';
import 'package:gymrank/features/workout_session/data/repositories/firestore_workout_session_repository.dart';
import 'package:gymrank/features/workout_session/domain/entities/workout_session.dart';
import 'package:gymrank/features/workout_session/domain/repositories/workout_session_repository.dart';
import 'package:gymrank/features/workout_session/domain/usecases/today_workout_planner.dart';

final workoutSessionRepositoryProvider = Provider<WorkoutSessionRepository>((ref) {
  return FirestoreWorkoutSessionRepository(ref.watch(firestoreProvider));
});

/// Sessão em andamento do usuário logado (para retomar), ou `null`.
final activeSessionProvider = StreamProvider<WorkoutSessionEntity?>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull;
  if (uid == null) return Stream.value(null);
  return ref.watch(workoutSessionRepositoryProvider).watchActive(uid);
});

final sessionProvider =
    StreamProvider.family<WorkoutSessionEntity?, String>((ref, sessionId) {
  return ref.watch(workoutSessionRepositoryProvider).watch(sessionId);
});

final recentSessionsProvider =
    StreamProvider.family<List<WorkoutSessionEntity>, String>((ref, userId) {
  return ref.watch(workoutSessionRepositoryProvider).watchRecent(userId, limit: 20);
});

/// Cartão "Entrenamiento de hoy": combina plano vigente, histórico e
/// sessão ativa numa regra pura ([TodayWorkoutPlanner]).
final todayWorkoutProvider = Provider<AsyncValue<TodayWorkout>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const AsyncValue.loading();

  final plans = ref.watch(myPlansProvider);
  final recent = ref.watch(recentSessionsProvider(user.id));
  final active = ref.watch(activeSessionProvider);

  final error = plans.error ?? recent.error ?? active.error;
  if (error != null) {
    return AsyncValue.error(
      error,
      plans.stackTrace ?? recent.stackTrace ?? active.stackTrace ?? StackTrace.current,
    );
  }
  if (!plans.hasValue || !recent.hasValue || !active.hasValue) {
    return const AsyncValue.loading();
  }

  return AsyncValue.data(
    TodayWorkoutPlanner.plan(
      plans: plans.value!,
      recentSessions: recent.value!,
      activeSession: active.value,
      userId: user.id,
      coachId: user.coachId,
    ),
  );
});
