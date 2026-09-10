// Modelos de conteúdo dos planos. Espelham os esquemas de saída do parser
// em functions/src/plans/planSchemas.ts — mudar lá exige mudar aqui.
//
// São classes MUTÁVEIS de propósito: a tela de revisão edita o rascunho
// em memória (adicionar/remover/alterar linhas) antes de serializar com
// `toMap()` na publicação. Fora da revisão, trate como somente leitura.
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';

String? _str(dynamic v) => v?.toString();

int? _int(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');

double? _num(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}');

List<Map<String, dynamic>> _listOfMaps(dynamic v) => [
      if (v is List)
        for (final e in v)
          if (e is Map) Map<String, dynamic>.from(e),
    ];

List<String> _listOfStrings(dynamic v) =>
    [if (v is List) for (final e in v) e.toString()];

/// Campos comuns a todos os tipos.
abstract class PlanContent {
  PlanContent({
    required this.title,
    this.summary,
    this.generalNotes,
    this.confidence = 'media',
    List<String>? warnings,
  }) : warnings = warnings ?? [];

  String title;
  String? summary;
  String? generalNotes;

  /// `alta` | `media` | `baja`, informado pelo parser.
  String confidence;
  List<String> warnings;

  PlanKind get kind;

  Map<String, dynamic> toMap();

  Map<String, dynamic> _baseMap() => {
        'title': title,
        'summary': summary,
        'generalNotes': generalNotes,
        'confidence': confidence,
        'warnings': warnings,
      };

  /// Constrói o modelo certo a partir do mapa persistido/parseado.
  static PlanContent fromMap(PlanKind kind, Map<String, dynamic> map) {
    return switch (kind) {
      PlanKind.entrenamiento => WorkoutPlanContent.fromMap(map),
      PlanKind.dieta => DietPlanContent.fromMap(map),
      PlanKind.macros => MacrosPlanContent.fromMap(map),
      PlanKind.evaluacion => EvaluationContent.fromMap(map),
      PlanKind.otro => GenericContent.fromMap(map),
    };
  }

  /// Rascunho vazio para captura manual.
  static PlanContent empty(PlanKind kind) => fromMap(kind, {'title': ''});
}

// ---------------------------------------------------------------------------
// Entrenamiento
// ---------------------------------------------------------------------------

class WorkoutExercise {
  WorkoutExercise({
    required this.name,
    this.sets,
    this.reps,
    this.load,
    this.restSeconds,
    this.technique,
    this.notes,
  });

  String name;
  int? sets;
  String? reps;
  String? load;
  int? restSeconds;
  String? technique;
  String? notes;

  factory WorkoutExercise.fromMap(Map<String, dynamic> m) => WorkoutExercise(
        name: _str(m['name']) ?? '',
        sets: _int(m['sets']),
        reps: _str(m['reps']),
        load: _str(m['load']),
        restSeconds: _int(m['restSeconds']),
        technique: _str(m['technique']),
        notes: _str(m['notes']),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'load': load,
        'restSeconds': restSeconds,
        'technique': technique,
        'notes': notes,
      };

  /// "4 × 10-12 · 40 kg · 90 s"
  String get prescription {
    final parts = <String>[
      if (sets != null || reps != null)
        [if (sets != null) '$sets', if (reps != null) reps!].join(' × '),
      if (load != null && load!.isNotEmpty) load!,
      if (restSeconds != null) '${restSeconds}s',
    ];
    return parts.join(' · ');
  }
}

class WorkoutDay {
  WorkoutDay({
    required this.name,
    this.focus,
    List<WorkoutExercise>? exercises,
    this.notes,
  }) : exercises = exercises ?? [];

  String name;
  String? focus;
  List<WorkoutExercise> exercises;
  String? notes;

  factory WorkoutDay.fromMap(Map<String, dynamic> m) => WorkoutDay(
        name: _str(m['name']) ?? '',
        focus: _str(m['focus']),
        exercises:
            _listOfMaps(m['exercises']).map(WorkoutExercise.fromMap).toList(),
        notes: _str(m['notes']),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'focus': focus,
        'exercises': exercises.map((e) => e.toMap()).toList(),
        'notes': notes,
      };
}

class WorkoutPlanContent extends PlanContent {
  WorkoutPlanContent({
    required super.title,
    super.summary,
    super.generalNotes,
    super.confidence,
    super.warnings,
    this.weeksDuration,
    List<WorkoutDay>? days,
  }) : days = days ?? [];

  int? weeksDuration;
  List<WorkoutDay> days;

  @override
  PlanKind get kind => PlanKind.entrenamiento;

  factory WorkoutPlanContent.fromMap(Map<String, dynamic> m) =>
      WorkoutPlanContent(
        title: _str(m['title']) ?? '',
        summary: _str(m['summary']),
        generalNotes: _str(m['generalNotes']),
        confidence: _str(m['confidence']) ?? 'media',
        warnings: _listOfStrings(m['warnings']),
        weeksDuration: _int(m['weeksDuration']),
        days: _listOfMaps(m['days']).map(WorkoutDay.fromMap).toList(),
      );

  @override
  Map<String, dynamic> toMap() => {
        ..._baseMap(),
        'weeksDuration': weeksDuration,
        'days': days.map((d) => d.toMap()).toList(),
      };
}

// ---------------------------------------------------------------------------
// Dieta
// ---------------------------------------------------------------------------

class MealItem {
  MealItem({required this.food, this.quantity, this.notes});

  String food;
  String? quantity;
  String? notes;

  factory MealItem.fromMap(Map<String, dynamic> m) => MealItem(
        food: _str(m['food']) ?? '',
        quantity: _str(m['quantity']),
        notes: _str(m['notes']),
      );

  Map<String, dynamic> toMap() =>
      {'food': food, 'quantity': quantity, 'notes': notes};
}

class Meal {
  Meal({required this.name, this.time, List<MealItem>? items, this.notes})
      : items = items ?? [];

  String name;
  String? time;
  List<MealItem> items;
  String? notes;

  factory Meal.fromMap(Map<String, dynamic> m) => Meal(
        name: _str(m['name']) ?? '',
        time: _str(m['time']),
        items: _listOfMaps(m['items']).map(MealItem.fromMap).toList(),
        notes: _str(m['notes']),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'time': time,
        'items': items.map((i) => i.toMap()).toList(),
        'notes': notes,
      };
}

class DietPlanContent extends PlanContent {
  DietPlanContent({
    required super.title,
    super.summary,
    super.generalNotes,
    super.confidence,
    super.warnings,
    List<Meal>? meals,
    List<String>? substitutions,
  })  : meals = meals ?? [],
        substitutions = substitutions ?? [];

  List<Meal> meals;
  List<String> substitutions;

  @override
  PlanKind get kind => PlanKind.dieta;

  factory DietPlanContent.fromMap(Map<String, dynamic> m) => DietPlanContent(
        title: _str(m['title']) ?? '',
        summary: _str(m['summary']),
        generalNotes: _str(m['generalNotes']),
        confidence: _str(m['confidence']) ?? 'media',
        warnings: _listOfStrings(m['warnings']),
        meals: _listOfMaps(m['meals']).map(Meal.fromMap).toList(),
        substitutions: _listOfStrings(m['substitutions']),
      );

  @override
  Map<String, dynamic> toMap() => {
        ..._baseMap(),
        'meals': meals.map((x) => x.toMap()).toList(),
        'substitutions': substitutions,
      };
}

// ---------------------------------------------------------------------------
// Macros
// ---------------------------------------------------------------------------

class MacroTarget {
  MacroTarget({
    required this.label,
    this.kcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.waterMl,
  });

  String label;
  double? kcal;
  double? proteinG;
  double? carbsG;
  double? fatG;
  double? fiberG;
  double? waterMl;

  factory MacroTarget.fromMap(Map<String, dynamic> m) => MacroTarget(
        label: _str(m['label']) ?? '',
        kcal: _num(m['kcal']),
        proteinG: _num(m['proteinG']),
        carbsG: _num(m['carbsG']),
        fatG: _num(m['fatG']),
        fiberG: _num(m['fiberG']),
        waterMl: _num(m['waterMl']),
      );

  Map<String, dynamic> toMap() => {
        'label': label,
        'kcal': kcal,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'fiberG': fiberG,
        'waterMl': waterMl,
      };
}

class MacrosPlanContent extends PlanContent {
  MacrosPlanContent({
    required super.title,
    super.summary,
    super.generalNotes,
    super.confidence,
    super.warnings,
    List<MacroTarget>? targets,
  }) : targets = targets ?? [];

  List<MacroTarget> targets;

  @override
  PlanKind get kind => PlanKind.macros;

  factory MacrosPlanContent.fromMap(Map<String, dynamic> m) =>
      MacrosPlanContent(
        title: _str(m['title']) ?? '',
        summary: _str(m['summary']),
        generalNotes: _str(m['generalNotes']),
        confidence: _str(m['confidence']) ?? 'media',
        warnings: _listOfStrings(m['warnings']),
        targets: _listOfMaps(m['targets']).map(MacroTarget.fromMap).toList(),
      );

  @override
  Map<String, dynamic> toMap() => {
        ..._baseMap(),
        'targets': targets.map((t) => t.toMap()).toList(),
      };
}

// ---------------------------------------------------------------------------
// Evaluación
// ---------------------------------------------------------------------------

class EvaluationMetric {
  EvaluationMetric({required this.label, required this.value, this.unit});

  String label;
  String value;
  String? unit;

  factory EvaluationMetric.fromMap(Map<String, dynamic> m) => EvaluationMetric(
        label: _str(m['label']) ?? '',
        value: _str(m['value']) ?? '',
        unit: _str(m['unit']),
      );

  Map<String, dynamic> toMap() => {'label': label, 'value': value, 'unit': unit};
}

class EvaluationContent extends PlanContent {
  EvaluationContent({
    required super.title,
    super.summary,
    super.generalNotes,
    super.confidence,
    super.warnings,
    this.recordedAt,
    List<EvaluationMetric>? metrics,
  }) : metrics = metrics ?? [];

  String? recordedAt;
  List<EvaluationMetric> metrics;

  @override
  PlanKind get kind => PlanKind.evaluacion;

  factory EvaluationContent.fromMap(Map<String, dynamic> m) =>
      EvaluationContent(
        title: _str(m['title']) ?? '',
        summary: _str(m['summary']),
        generalNotes: _str(m['generalNotes']),
        confidence: _str(m['confidence']) ?? 'media',
        warnings: _listOfStrings(m['warnings']),
        recordedAt: _str(m['recordedAt']),
        metrics:
            _listOfMaps(m['metrics']).map(EvaluationMetric.fromMap).toList(),
      );

  @override
  Map<String, dynamic> toMap() => {
        ..._baseMap(),
        'recordedAt': recordedAt,
        'metrics': metrics.map((x) => x.toMap()).toList(),
      };
}

// ---------------------------------------------------------------------------
// Otro
// ---------------------------------------------------------------------------

class GenericSection {
  GenericSection({required this.heading, required this.content});

  String heading;
  String content;

  factory GenericSection.fromMap(Map<String, dynamic> m) => GenericSection(
        heading: _str(m['heading']) ?? '',
        content: _str(m['content']) ?? '',
      );

  Map<String, dynamic> toMap() => {'heading': heading, 'content': content};
}

class GenericContent extends PlanContent {
  GenericContent({
    required super.title,
    super.summary,
    super.generalNotes,
    super.confidence,
    super.warnings,
    List<GenericSection>? sections,
  }) : sections = sections ?? [];

  List<GenericSection> sections;

  @override
  PlanKind get kind => PlanKind.otro;

  factory GenericContent.fromMap(Map<String, dynamic> m) => GenericContent(
        title: _str(m['title']) ?? '',
        summary: _str(m['summary']),
        generalNotes: _str(m['generalNotes']),
        confidence: _str(m['confidence']) ?? 'media',
        warnings: _listOfStrings(m['warnings']),
        sections:
            _listOfMaps(m['sections']).map(GenericSection.fromMap).toList(),
      );

  @override
  Map<String, dynamic> toMap() => {
        ..._baseMap(),
        'sections': sections.map((s) => s.toMap()).toList(),
      };
}
