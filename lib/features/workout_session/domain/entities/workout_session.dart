// Sessão de treino executada a partir do plano publicado
// (`workout_sessions/{sessionId}`). Modelos mutáveis de propósito: a tela
// de execução edita séries em memória e salva em lotes; fora dela, trate
// como somente leitura. Espelhado em
// functions/src/training/onWorkoutSessionCompleted.ts.
import 'package:gymrank/features/plans/domain/entities/plan_content.dart';

enum SessionStatus { enCurso, completada, cancelada }

/// Fórmula de Epley para 1RM estimado: carga × (1 + reps / 30).
double estimateOneRepMax(double load, int reps) => load * (1 + reps / 30);

class SessionSet {
  SessionSet({this.reps, this.load, this.rpe, this.done = false});

  int? reps;
  double? load;
  double? rpe;
  bool done;

  double get volume =>
      (done && reps != null && load != null) ? reps! * load! : 0;

  double? get estimated1Rm => (done && reps != null && load != null && reps! > 0 && load! > 0)
      ? estimateOneRepMax(load!, reps!)
      : null;

  factory SessionSet.fromMap(Map<String, dynamic> m) => SessionSet(
        reps: (m['reps'] as num?)?.toInt(),
        load: (m['load'] as num?)?.toDouble(),
        rpe: (m['rpe'] as num?)?.toDouble(),
        done: m['done'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() =>
      {'reps': reps, 'load': load, 'rpe': rpe, 'done': done};
}

class SessionExercise {
  SessionExercise({
    required this.name,
    required this.targetSets,
    this.targetReps,
    this.targetLoad,
    this.restSeconds,
    this.technique,
    this.notes,
    List<SessionSet>? sets,
  }) : sets = sets ?? [];

  String name;
  int targetSets;
  String? targetReps;
  String? targetLoad;
  int? restSeconds;
  String? technique;
  String? notes;
  List<SessionSet> sets;

  int get doneSets => sets.where((s) => s.done).length;

  double get volume => sets.fold(0, (sum, s) => sum + s.volume);

  /// "4 × 10-12 · RPE 8 · 90 s"
  String get prescription => [
        [
          '$targetSets',
          if (targetReps != null && targetReps!.isNotEmpty) targetReps!,
        ].join(' × '),
        if (targetLoad != null && targetLoad!.isNotEmpty) targetLoad!,
        if (restSeconds != null) '${restSeconds}s descanso',
      ].join(' · ');

  /// Constrói a partir da prescrição do plano, pré-preenchendo carga e
  /// repetições com o que o aluno fez da última vez (se houver).
  factory SessionExercise.fromPlan(
    WorkoutExercise ex, {
    SessionSet? previous,
  }) {
    final targetSets = (ex.sets ?? 3).clamp(1, 12);
    final repsGuess = previous?.reps ?? _firstInt(ex.reps);
    final loadGuess = previous?.load ?? _firstDouble(ex.load);
    return SessionExercise(
      name: ex.name,
      targetSets: targetSets,
      targetReps: ex.reps,
      targetLoad: ex.load,
      restSeconds: ex.restSeconds,
      technique: ex.technique,
      notes: ex.notes,
      sets: [
        for (var i = 0; i < targetSets; i++)
          SessionSet(reps: repsGuess, load: loadGuess),
      ],
    );
  }

  factory SessionExercise.fromMap(Map<String, dynamic> m) => SessionExercise(
        name: m['name'] as String? ?? '',
        targetSets: (m['targetSets'] as num?)?.toInt() ?? 3,
        targetReps: m['targetReps'] as String?,
        targetLoad: m['targetLoad'] as String?,
        restSeconds: (m['restSeconds'] as num?)?.toInt(),
        technique: m['technique'] as String?,
        notes: m['notes'] as String?,
        sets: [
          if (m['sets'] is List)
            for (final s in m['sets'] as List)
              if (s is Map) SessionSet.fromMap(Map<String, dynamic>.from(s)),
        ],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'targetSets': targetSets,
        'targetReps': targetReps,
        'targetLoad': targetLoad,
        'restSeconds': restSeconds,
        'technique': technique,
        'notes': notes,
        'sets': sets.map((s) => s.toMap()).toList(),
      };

  static int? _firstInt(String? raw) {
    if (raw == null) return null;
    final match = RegExp(r'\d+').firstMatch(raw);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  /// "40 kg" → 40; "RPE 8" → null (não é carga).
  static double? _firstDouble(String? raw) {
    if (raw == null) return null;
    final lower = raw.toLowerCase();
    if (lower.contains('rpe') || lower.contains('rir')) return null;
    final match = RegExp(r'\d+([.,]\d+)?').firstMatch(raw);
    return match == null
        ? null
        : double.tryParse(match.group(0)!.replaceAll(',', '.'));
  }
}

/// Recorde pessoal detectado pela Cloud Function ao concluir a sessão.
class PersonalRecord {
  const PersonalRecord({
    required this.exercise,
    required this.load,
    required this.reps,
    required this.estimated1Rm,
  });

  final String exercise;
  final double load;
  final int reps;
  final double estimated1Rm;

  factory PersonalRecord.fromMap(Map<String, dynamic> m) => PersonalRecord(
        exercise: m['exercise'] as String? ?? '',
        load: (m['load'] as num?)?.toDouble() ?? 0,
        reps: (m['reps'] as num?)?.toInt() ?? 0,
        estimated1Rm: (m['estimated1Rm'] as num?)?.toDouble() ?? 0,
      );
}

class WorkoutSessionEntity {
  WorkoutSessionEntity({
    required this.id,
    required this.userId,
    required this.coachId,
    required this.planId,
    required this.planVersion,
    required this.dayIndex,
    required this.dayName,
    required this.status,
    required this.startedAt,
    required this.exercises,
    this.finishedAt,
    this.durationSec,
    this.totalVolumeKg = 0,
    this.validated,
    this.validationReason,
    this.prs = const [],
    this.countedForStreak,
    this.xpGranted,
  });

  final String id;
  final String userId;
  final String? coachId;
  final String planId;
  final int planVersion;
  final int dayIndex;
  final String dayName;
  SessionStatus status;
  final DateTime startedAt;
  DateTime? finishedAt;
  int? durationSec;
  final List<SessionExercise> exercises;
  double totalVolumeKg;

  // Campos escritos só pela Cloud Function.
  final bool? validated;
  final String? validationReason;
  final List<PersonalRecord> prs;
  final bool? countedForStreak;
  final int? xpGranted;

  int get totalSets => exercises.fold(0, (n, e) => n + e.sets.length);

  int get doneSets => exercises.fold(0, (n, e) => n + e.doneSets);

  double get computedVolume => exercises.fold(0, (v, e) => v + e.volume);

  /// Estimativa grosseira para o cartão da home: 45 s por série + descanso.
  int get estimatedMinutes {
    var seconds = 0;
    for (final e in exercises) {
      seconds += e.targetSets * (45 + (e.restSeconds ?? 60));
    }
    return (seconds / 60).ceil();
  }

  WorkoutSessionEntity copyWithId(String newId) => WorkoutSessionEntity(
        id: newId,
        userId: userId,
        coachId: coachId,
        planId: planId,
        planVersion: planVersion,
        dayIndex: dayIndex,
        dayName: dayName,
        status: status,
        startedAt: startedAt,
        exercises: exercises,
        finishedAt: finishedAt,
        durationSec: durationSec,
        totalVolumeKg: totalVolumeKg,
        validated: validated,
        validationReason: validationReason,
        prs: prs,
        countedForStreak: countedForStreak,
        xpGranted: xpGranted,
      );
}
