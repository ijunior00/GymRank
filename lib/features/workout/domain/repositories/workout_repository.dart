import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/workout/domain/entities/workout_entity.dart';

abstract interface class WorkoutRepository {
  Stream<List<WorkoutEntity>> watchRecent(String userId, {int limit});

  Future<Result<WorkoutEntity>> log(WorkoutEntity workout);
}
