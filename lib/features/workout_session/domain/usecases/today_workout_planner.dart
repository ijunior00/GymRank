import 'package:gymrank/features/plans/domain/entities/plan_content.dart';
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';
import 'package:gymrank/features/workout_session/domain/entities/workout_session.dart';

/// O que a home mostra no cartão "Entrenamiento de hoy".
sealed class TodayWorkout {
  const TodayWorkout();
}

/// Sem plano de treino publicado: oferece o registro manual.
class TodayWorkoutNoPlan extends TodayWorkout {
  const TodayWorkoutNoPlan();
}

/// Há uma sessão em andamento para retomar.
class TodayWorkoutInProgress extends TodayWorkout {
  const TodayWorkoutInProgress(this.session);

  final WorkoutSessionEntity session;
}

/// Próxima sessão do plano, pronta para começar.
class TodayWorkoutReady extends TodayWorkout {
  const TodayWorkoutReady({
    required this.plan,
    required this.dayIndex,
    required this.day,
    required this.draft,
    required this.trainedToday,
  });

  final PlanEntity plan;
  final int dayIndex;
  final WorkoutDay day;

  /// Sessão pronta para ser criada (`id` vazio), com cargas pré-preenchidas.
  final WorkoutSessionEntity draft;

  /// Já concluiu uma sessão hoje: o cartão avisa, mas deixa treinar de novo.
  final bool trainedToday;
}

/// Regra pura: decide a próxima sessão a partir do plano vigente e do
/// histórico recente. Testável sem Firebase.
abstract final class TodayWorkoutPlanner {
  static TodayWorkout plan({
    required List<PlanEntity> plans,
    required List<WorkoutSessionEntity> recentSessions,
    required WorkoutSessionEntity? activeSession,
    required String userId,
    required String? coachId,
    DateTime? now,
  }) {
    if (activeSession != null) return TodayWorkoutInProgress(activeSession);

    PlanEntity? workoutPlan;
    for (final p in plans) {
      if (p.kind == PlanKind.entrenamiento) {
        workoutPlan = p;
        break;
      }
    }
    if (workoutPlan == null) return const TodayWorkoutNoPlan();

    final content = WorkoutPlanContent.fromMap(workoutPlan.content);
    if (content.days.isEmpty) return const TodayWorkoutNoPlan();

    final completed = recentSessions
        .where((s) => s.status == SessionStatus.completada)
        .toList()
      ..sort((a, b) => (b.finishedAt ?? b.startedAt)
          .compareTo(a.finishedAt ?? a.startedAt));

    // Próximo dia: o seguinte ao último concluído deste plano (cíclico).
    var nextIndex = 0;
    for (final s in completed) {
      if (s.planId == workoutPlan.id) {
        nextIndex = (s.dayIndex + 1) % content.days.length;
        break;
      }
    }

    final today = now ?? DateTime.now();
    final trainedToday = completed.any((s) {
      final f = s.finishedAt ?? s.startedAt;
      return f.year == today.year && f.month == today.month && f.day == today.day;
    });

    final day = content.days[nextIndex];
    final previousByExercise = _lastSetsByExercise(completed);
    final draft = WorkoutSessionEntity(
      id: '',
      userId: userId,
      coachId: coachId,
      planId: workoutPlan.id,
      planVersion: workoutPlan.currentVersion,
      dayIndex: nextIndex,
      dayName: day.name,
      status: SessionStatus.enCurso,
      startedAt: today,
      exercises: [
        for (final ex in day.exercises)
          SessionExercise.fromPlan(
            ex,
            previous: previousByExercise[_key(ex.name)],
          ),
      ],
    );

    return TodayWorkoutReady(
      plan: workoutPlan,
      dayIndex: nextIndex,
      day: day,
      draft: draft,
      trainedToday: trainedToday,
    );
  }

  /// Última série concluída de cada exercício (mais recente primeiro),
  /// para pré-preencher carga/reps na próxima sessão.
  static Map<String, SessionSet> _lastSetsByExercise(
    List<WorkoutSessionEntity> completedNewestFirst,
  ) {
    final map = <String, SessionSet>{};
    for (final s in completedNewestFirst) {
      for (final ex in s.exercises) {
        final key = _key(ex.name);
        if (map.containsKey(key)) continue;
        final done = ex.sets.where((x) => x.done && x.load != null).toList();
        if (done.isNotEmpty) map[key] = done.last;
      }
    }
    return map;
  }

  static String _key(String name) => name.trim().toLowerCase();
}
