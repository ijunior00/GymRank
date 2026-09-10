import 'package:flutter_test/flutter_test.dart';
import 'package:gymrank/features/plans/domain/entities/plan_content.dart';
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';
import 'package:gymrank/features/workout_session/domain/entities/workout_session.dart';
import 'package:gymrank/features/workout_session/domain/usecases/today_workout_planner.dart';

/// Regra do cartão "Entrenamiento de hoy" da home.
void main() {
  PlanEntity workoutPlan({
    String id = 'plan-1',
    List<String> days = const ['Día 1 · Pierna', 'Día 2 · Empuje'],
  }) {
    return PlanEntity(
      id: id,
      coachId: 'c1',
      userId: 'u1',
      kind: PlanKind.entrenamiento,
      title: 'Método VF · Fuerza',
      currentVersion: 3,
      content: WorkoutPlanContent(
        title: 'Método VF · Fuerza',
        days: [
          for (final name in days)
            WorkoutDay(
              name: name,
              exercises: [
                WorkoutExercise(name: 'Sentadilla', sets: 3, reps: '10', load: '60 kg'),
              ],
            ),
        ],
      ).toMap(),
      sourceDocumentId: null,
      publishedAt: DateTime(2026, 1, 1),
      publishedBy: 'c1',
    );
  }

  PlanEntity dietPlan() => PlanEntity(
        id: 'plan-dieta',
        coachId: 'c1',
        userId: 'u1',
        kind: PlanKind.dieta,
        title: 'Plan de alimentación',
        currentVersion: 1,
        content: DietPlanContent(title: 'Plan de alimentación').toMap(),
        sourceDocumentId: null,
        publishedAt: DateTime(2026, 1, 1),
        publishedBy: 'c1',
      );

  WorkoutSessionEntity completed({
    required int dayIndex,
    required DateTime finishedAt,
    String planId = 'plan-1',
    List<SessionExercise>? exercises,
  }) =>
      WorkoutSessionEntity(
        id: 'sess-$dayIndex-${finishedAt.millisecondsSinceEpoch}',
        userId: 'u1',
        coachId: 'c1',
        planId: planId,
        planVersion: 3,
        dayIndex: dayIndex,
        dayName: 'Día ${dayIndex + 1}',
        status: SessionStatus.completada,
        startedAt: finishedAt.subtract(const Duration(minutes: 50)),
        finishedAt: finishedAt,
        exercises: exercises ?? const [],
      );

  test('sem plano de treino publicado, oferece registro manual', () {
    final result = TodayWorkoutPlanner.plan(
      plans: [dietPlan()],
      recentSessions: const [],
      activeSession: null,
      userId: 'u1',
      coachId: 'c1',
    );
    expect(result, isA<TodayWorkoutNoPlan>());
  });

  test('plano de treino sem dias também cai no registro manual', () {
    final result = TodayWorkoutPlanner.plan(
      plans: [workoutPlan(days: const [])],
      recentSessions: const [],
      activeSession: null,
      userId: 'u1',
      coachId: 'c1',
    );
    expect(result, isA<TodayWorkoutNoPlan>());
  });

  test('uma sessão em andamento vem antes de tudo', () {
    final active = WorkoutSessionEntity(
      id: 'ativa',
      userId: 'u1',
      coachId: 'c1',
      planId: 'plan-1',
      planVersion: 3,
      dayIndex: 0,
      dayName: 'Día 1',
      status: SessionStatus.enCurso,
      startedAt: DateTime(2026, 3, 2, 7),
      exercises: const [],
    );

    final result = TodayWorkoutPlanner.plan(
      plans: [workoutPlan()],
      recentSessions: const [],
      activeSession: active,
      userId: 'u1',
      coachId: 'c1',
    );

    expect(result, isA<TodayWorkoutInProgress>());
    expect((result as TodayWorkoutInProgress).session.id, 'ativa');
  });

  test('sem histórico, começa pelo primeiro dia', () {
    final result = TodayWorkoutPlanner.plan(
      plans: [workoutPlan()],
      recentSessions: const [],
      activeSession: null,
      userId: 'u1',
      coachId: 'c1',
      now: DateTime(2026, 3, 2, 7),
    ) as TodayWorkoutReady;

    expect(result.dayIndex, 0);
    expect(result.day.name, 'Día 1 · Pierna');
    expect(result.draft.id, isEmpty, reason: 'ainda não foi criada');
    expect(result.draft.planVersion, 3);
    expect(result.trainedToday, isFalse);
  });

  test('vai para o dia seguinte ao último concluído e dá a volta', () {
    final plan = workoutPlan();

    final apos0 = TodayWorkoutPlanner.plan(
      plans: [plan],
      recentSessions: [completed(dayIndex: 0, finishedAt: DateTime(2026, 3, 1, 8))],
      activeSession: null,
      userId: 'u1',
      coachId: 'c1',
      now: DateTime(2026, 3, 2, 7),
    ) as TodayWorkoutReady;
    expect(apos0.dayIndex, 1);

    final apos1 = TodayWorkoutPlanner.plan(
      plans: [plan],
      recentSessions: [
        completed(dayIndex: 1, finishedAt: DateTime(2026, 3, 2, 8)),
        completed(dayIndex: 0, finishedAt: DateTime(2026, 3, 1, 8)),
      ],
      activeSession: null,
      userId: 'u1',
      coachId: 'c1',
      now: DateTime(2026, 3, 3, 7),
    ) as TodayWorkoutReady;
    expect(apos1.dayIndex, 0, reason: 'o rodízio é cíclico');
  });

  test('usa a sessão mais recente mesmo se a lista vier fora de ordem', () {
    final result = TodayWorkoutPlanner.plan(
      plans: [workoutPlan()],
      recentSessions: [
        completed(dayIndex: 0, finishedAt: DateTime(2026, 3, 1, 8)),
        completed(dayIndex: 1, finishedAt: DateTime(2026, 3, 2, 8)),
      ],
      activeSession: null,
      userId: 'u1',
      coachId: 'c1',
      now: DateTime(2026, 3, 3, 7),
    ) as TodayWorkoutReady;

    expect(result.dayIndex, 0);
  });

  test('sessões de outro plano não movem o rodízio', () {
    final result = TodayWorkoutPlanner.plan(
      plans: [workoutPlan()],
      recentSessions: [
        completed(
          dayIndex: 4,
          finishedAt: DateTime(2026, 3, 1, 8),
          planId: 'plan-antigo',
        ),
      ],
      activeSession: null,
      userId: 'u1',
      coachId: 'c1',
      now: DateTime(2026, 3, 2, 7),
    ) as TodayWorkoutReady;

    expect(result.dayIndex, 0);
  });

  test('avisa que já treinou hoje, mas deixa treinar de novo', () {
    final result = TodayWorkoutPlanner.plan(
      plans: [workoutPlan()],
      recentSessions: [completed(dayIndex: 0, finishedAt: DateTime(2026, 3, 2, 8))],
      activeSession: null,
      userId: 'u1',
      coachId: 'c1',
      now: DateTime(2026, 3, 2, 19),
    ) as TodayWorkoutReady;

    expect(result.trainedToday, isTrue);
    expect(result.dayIndex, 1);
  });

  test('pré-preenche a carga com a última série feita daquele exercício', () {
    final result = TodayWorkoutPlanner.plan(
      plans: [workoutPlan()],
      recentSessions: [
        completed(
          dayIndex: 1,
          finishedAt: DateTime(2026, 3, 1, 8),
          exercises: [
            SessionExercise(
              name: '  SENTADILLA ',
              targetSets: 2,
              sets: [
                SessionSet(reps: 10, load: 70, done: true),
                SessionSet(reps: 8, load: 77.5, done: true),
              ],
            ),
          ],
        ),
      ],
      activeSession: null,
      userId: 'u1',
      coachId: 'c1',
      now: DateTime(2026, 3, 2, 7),
    ) as TodayWorkoutReady;

    final first = result.draft.exercises.single.sets.first;
    expect(first.load, 77.5, reason: 'a última série feita, não a do plano');
    expect(first.reps, 8);
    expect(first.done, isFalse);
  });
}
