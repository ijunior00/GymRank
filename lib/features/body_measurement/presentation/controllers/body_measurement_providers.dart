import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/body_measurement/data/repositories/firestore_body_measurement_repository.dart';
import 'package:gymrank/features/body_measurement/domain/entities/body_measurement_entity.dart';
import 'package:gymrank/features/body_measurement/domain/repositories/body_measurement_repository.dart';

final bodyMeasurementRepositoryProvider =
    Provider<BodyMeasurementRepository>((ref) {
  return FirestoreBodyMeasurementRepository(ref.watch(firestoreProvider));
});

final bodyMeasurementHistoryProvider =
    StreamProvider<List<BodyMeasurementEntity>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull;
  if (uid == null) return Stream.value(const []);
  return ref.watch(bodyMeasurementRepositoryProvider).watchHistory(uid);
});
