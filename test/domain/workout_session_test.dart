import 'package:flutter_test/flutter_test.dart';
import 'package:gymrank/features/plans/domain/entities/plan_content.dart';
import 'package:gymrank/features/workout_session/domain/entities/workout_session.dart';

/// Os recordes do aluno saem do 1RM estimado; a mesma fórmula roda na
/// Cloud Function `onWorkoutSessionCompleted`.
void main() {
  group('estimateOneRepMax (Epley)', () {
    test('uma repetição é a própria carga', () {
      expect(estimateOneRepMax(100, 0), 100);
      expect(estimateOneRepMax(100, 30), 200);
    });

    test('mais repetições com a mesma carga valem mais', () {
      expect(estimateOneRepMax(80, 10), greaterThan(estimateOneRepMax(80, 5)));
      expect(estimateOneRepMax(80, 10), closeTo(106.666, 0.001));
    });
  });

  group('SessionSet', () {
    test('só conta volume e 1RM quando a série foi marcada', () {
      final pendente = SessionSet(reps: 10, load: 60);
      expect(pendente.volume, 0);
      expect(pendente.estimated1Rm, isNull);

      final feita = SessionSet(reps: 10, load: 60, done: true);
      expect(feita.volume, 600);
      expect(feita.estimated1Rm, closeTo(80, 0.001));
    });

    test('série sem carga ou sem reps não vira recorde', () {
      expect(SessionSet(reps: 10, done: true).estimated1Rm, isNull);
      expect(SessionSet(load: 60, done: true).estimated1Rm, isNull);
      expect(SessionSet(reps: 0, load: 60, done: true).estimated1Rm, isNull);
    });
  });

  group('SessionExercise.fromPlan', () {
    test('cria uma série por série prescrita e pré-preenche do plano', () {
      final ex = SessionExercise.fromPlan(
        WorkoutExercise(name: 'Sentadilla', sets: 4, reps: '10-12', load: '60 kg'),
      );
      expect(ex.sets.length, 4);
      expect(ex.sets.first.reps, 10, reason: 'o menor do intervalo 10-12');
      expect(ex.sets.first.load, 60);
      expect(ex.sets.every((s) => !s.done), isTrue);
    });

    test('RPE e RIR não são carga', () {
      final ex = SessionExercise.fromPlan(
        WorkoutExercise(name: 'Peso muerto', sets: 3, reps: '8', load: 'RPE 8'),
      );
      expect(ex.sets.first.load, isNull);
      expect(ex.sets.first.reps, 8);
    });

    test('sem prescrição de séries usa 3 e limita a 12', () {
      expect(SessionExercise.fromPlan(WorkoutExercise(name: 'Press')).sets.length, 3);
      expect(
        SessionExercise.fromPlan(WorkoutExercise(name: 'Press', sets: 40)).sets.length,
        12,
      );
    });

    test('o último treino manda sobre o plano', () {
      final ex = SessionExercise.fromPlan(
        WorkoutExercise(name: 'Sentadilla', sets: 2, reps: '10', load: '60 kg'),
        previous: SessionSet(reps: 8, load: 72.5, done: true),
      );
      expect(ex.sets.first.load, 72.5);
      expect(ex.sets.first.reps, 8);
    });
  });

  group('WorkoutSessionEntity', () {
    WorkoutSessionEntity session(List<SessionExercise> exercises) =>
        WorkoutSessionEntity(
          id: 's1',
          userId: 'u1',
          coachId: 'c1',
          planId: 'p1',
          planVersion: 1,
          dayIndex: 0,
          dayName: 'Día 1',
          status: SessionStatus.enCurso,
          startedAt: DateTime(2026, 1, 1, 7),
          exercises: exercises,
        );

    test('soma séries feitas e volume só do que foi marcado', () {
      final s = session([
        SessionExercise(
          name: 'Sentadilla',
          targetSets: 3,
          sets: [
            SessionSet(reps: 10, load: 60, done: true),
            SessionSet(reps: 10, load: 60, done: true),
            SessionSet(reps: 10, load: 60),
          ],
        ),
        SessionExercise(
          name: 'Press banca',
          targetSets: 1,
          sets: [SessionSet(reps: 8, load: 40, done: true)],
        ),
      ]);

      expect(s.totalSets, 4);
      expect(s.doneSets, 3);
      expect(s.computedVolume, 600 + 600 + 320);
    });

    test('uma sessão sem nada marcado não gera volume', () {
      final s = session([
        SessionExercise(
          name: 'Sentadilla',
          targetSets: 1,
          sets: [SessionSet(reps: 10, load: 60)],
        ),
      ]);
      expect(s.doneSets, 0);
      expect(s.computedVolume, 0);
    });
  });
}
