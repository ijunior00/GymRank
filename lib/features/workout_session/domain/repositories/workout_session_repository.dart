import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/workout_session/domain/entities/workout_session.dart';

abstract interface class WorkoutSessionRepository {
  /// Cria `workout_sessions/{id}` com status `enCurso` a partir do rascunho
  /// (id vazio) e devolve a sessão com id.
  Future<Result<WorkoutSessionEntity>> start(WorkoutSessionEntity draft);

  /// Salva séries/volume de uma sessão em andamento.
  Future<Result<void>> save(WorkoutSessionEntity session);

  /// Marca como `completada`. A validação (duração mínima, séries feitas),
  /// XP, sequência e recordes são calculados pela Cloud Function
  /// `onWorkoutSessionCompleted` — nunca pelo cliente.
  Future<Result<void>> finish(WorkoutSessionEntity session);

  Future<Result<void>> cancel(String sessionId);

  Stream<WorkoutSessionEntity?> watchActive(String userId);

  Stream<WorkoutSessionEntity?> watch(String sessionId);

  Stream<List<WorkoutSessionEntity>> watchRecent(String userId, {int limit});
}
