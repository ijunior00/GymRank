import 'package:flutter_test/flutter_test.dart';
import 'package:gymrank/features/plans/domain/entities/plan_content.dart';
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';

/// Estes modelos recebem a saída do leitor de PDF/Word (Cloud Function
/// `parseDocument`) e o que já está no Firestore. É entrada não confiável:
/// nenhum campo faltando ou com o tipo errado pode derrubar a revisão.
void main() {
  group('PlanContent.fromMap escolhe o modelo pelo tipo', () {
    test('cada tipo vira sua classe', () {
      expect(PlanContent.fromMap(PlanKind.entrenamiento, {}),
          isA<WorkoutPlanContent>());
      expect(PlanContent.fromMap(PlanKind.dieta, {}), isA<DietPlanContent>());
      expect(
          PlanContent.fromMap(PlanKind.macros, {}), isA<MacrosPlanContent>());
      expect(PlanContent.fromMap(PlanKind.evaluacion, {}),
          isA<EvaluationContent>());
      expect(PlanContent.fromMap(PlanKind.otro, {}), isA<GenericContent>());
    });

    test('empty() dá um rascunho vazio coerente com o tipo', () {
      for (final kind in PlanKind.values) {
        final draft = PlanContent.empty(kind);
        expect(draft.kind, kind);
        expect(draft.title, isEmpty);
        expect(draft.warnings, isEmpty);
        expect(draft.confidence, 'media');
      }
    });
  });

  group('WorkoutPlanContent', () {
    test('sobrevive a um mapa vazio', () {
      final content = WorkoutPlanContent.fromMap(const {});
      expect(content.title, isEmpty);
      expect(content.days, isEmpty);
      expect(content.weeksDuration, isNull);
      expect(content.confidence, 'media');
    });

    test('ignora dias e exercícios que não são mapas', () {
      final content = WorkoutPlanContent.fromMap(const {
        'title': 'Fuerza',
        'days': ['lixo', 42, null],
      });
      expect(content.days, isEmpty);
    });

    test('aceita números vindos como texto', () {
      final content = WorkoutPlanContent.fromMap(const {
        'title': 'Fuerza',
        'weeksDuration': '8',
        'days': [
          {
            'name': 'Día 1',
            'exercises': [
              {'name': 'Sentadilla', 'sets': '4', 'restSeconds': '90'},
            ],
          },
        ],
      });
      expect(content.weeksDuration, 8);
      expect(content.days.single.exercises.single.sets, 4);
      expect(content.days.single.exercises.single.restSeconds, 90);
    });

    test('vai e volta pelo toMap sem perder nada', () {
      final original = WorkoutPlanContent(
        title: 'Método AF · Fuerza',
        summary: 'Bloque 1',
        generalNotes: 'Calentar 10 min',
        confidence: 'alta',
        warnings: ['La página 3 estaba borrosa'],
        weeksDuration: 8,
        days: [
          WorkoutDay(
            name: 'Día 1 · Pierna',
            focus: 'Cuádriceps',
            notes: 'Sin prisa',
            exercises: [
              WorkoutExercise(
                name: 'Sentadilla',
                sets: 4,
                reps: '10-12',
                load: '60 kg',
                restSeconds: 90,
                technique: 'Tempo 3-1-1',
                notes: 'Cuidar rodillas',
              ),
            ],
          ),
        ],
      );

      final copy = WorkoutPlanContent.fromMap(original.toMap());

      expect(copy.toMap(), original.toMap());
      expect(copy.warnings, ['La página 3 estaba borrosa']);
      expect(copy.days.single.exercises.single.name, 'Sentadilla');
      expect(copy.days.single.exercises.single.restSeconds, 90);
    });
  });

  group('DietPlanContent', () {
    test('vai e volta pelo toMap sem perder nada', () {
      final original = DietPlanContent(
        title: 'Plan de alimentación',
        confidence: 'baja',
        warnings: ['No se detectaron cantidades'],
        meals: [
          Meal(
            name: 'Desayuno',
            time: '07:30',
            notes: 'Antes de entrenar',
            items: [
              MealItem(food: 'Avena', quantity: '60 g'),
              MealItem(food: 'Claras', quantity: '200 ml', notes: 'o 3 huevos'),
            ],
          ),
        ],
        substitutions: ['Avena por arroz inflado'],
      );

      final copy = DietPlanContent.fromMap(original.toMap());

      expect(copy.toMap(), original.toMap());
      expect(copy.meals.single.items, hasLength(2));
      expect(copy.substitutions, ['Avena por arroz inflado']);
    });

    test('sobrevive a comidas malformadas', () {
      final content = DietPlanContent.fromMap(const {
        'title': 'Dieta',
        'meals': [
          {'name': 'Comida', 'items': 'no es una lista'},
          'tampoco esto',
        ],
        'substitutions': 'ni esto',
      });
      expect(content.meals, hasLength(1));
      expect(content.meals.single.items, isEmpty);
      expect(content.substitutions, isEmpty);
    });
  });

  group('MacrosPlanContent', () {
    test('lê metas com números e com texto', () {
      final content = MacrosPlanContent.fromMap(const {
        'title': 'Macros',
        'targets': [
          {
            'label': 'Día de entrenamiento',
            'kcal': 2200,
            'proteinG': '160',
            'carbsG': 240.5,
            'fatG': null,
          },
        ],
      });

      final target = content.targets.single;
      expect(target.kcal, 2200);
      expect(target.proteinG, 160);
      expect(target.carbsG, 240.5);
      expect(target.fatG, isNull);
    });
  });
}
