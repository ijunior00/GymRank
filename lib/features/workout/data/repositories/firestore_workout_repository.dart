import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/workout/domain/entities/workout_entity.dart';
import 'package:gymrank/features/workout/domain/repositories/workout_repository.dart';

class FirestoreWorkoutRepository implements WorkoutRepository {
  FirestoreWorkoutRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('workouts');

  @override
  Stream<List<WorkoutEntity>> watchRecent(String userId, {int limit = 20}) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(_fromSnapshot).toList());
  }

  @override
  Future<Result<WorkoutEntity>> log(WorkoutEntity workout) async {
    try {
      final doc = await _collection.add({
        'userId': workout.userId,
        'date': Timestamp.fromDate(workout.date),
        'durationMinutes': workout.duration.inMinutes,
        'muscleGroup': workout.muscleGroup.name,
        'intensity': workout.intensity.name,
        'source': workout.source.name,
        'note': workout.note,
        'createdAt': Timestamp.fromDate(workout.createdAt),
      });
      return Result.success(workout.copyWith(id: doc.id));
    } on FirebaseException catch (e) {
      return Result.failure(Failure.unexpected(e.message ?? e.code));
    }
  }

  WorkoutEntity _fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return WorkoutEntity(
      id: doc.id,
      userId: data['userId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      duration: Duration(minutes: data['durationMinutes'] as int),
      muscleGroup: MuscleGroup.values.byName(data['muscleGroup'] as String),
      intensity: WorkoutIntensity.values.byName(data['intensity'] as String),
      source: WorkoutSource.values.byName(data['source'] as String),
      note: data['note'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
