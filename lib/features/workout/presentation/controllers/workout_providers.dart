import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/workout/data/repositories/firestore_workout_repository.dart';
import 'package:gymrank/features/workout/domain/repositories/workout_repository.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return FirestoreWorkoutRepository(ref.watch(firestoreProvider));
});
