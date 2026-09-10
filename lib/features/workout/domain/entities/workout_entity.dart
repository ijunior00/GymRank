import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_entity.freezed.dart';

enum MuscleGroup {
  peito,
  costas,
  pernas,
  ombro,
  biceps,
  triceps,
  abdomen,
  cardio,
  corpoInteiro,
}

enum WorkoutIntensity { leve, moderada, intensa }

/// `plan` = resumo criado pela Cloud Function ao concluir uma sessão do
/// plano publicado (`workout_sessions`).
enum WorkoutSource { manual, plan, hevy, strong, appleHealth, googleFit }

/// Documento canônico de `workouts/{workoutId}`.
@freezed
class WorkoutEntity with _$WorkoutEntity {
  const factory WorkoutEntity({
    required String id,
    required String userId,
    required DateTime date,
    required Duration duration,
    required MuscleGroup muscleGroup,
    required WorkoutIntensity intensity,
    required WorkoutSource source,
    String? note,
    required DateTime createdAt,
  }) = _WorkoutEntity;
}
