import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/gym_admin/data/repositories/firestore_gym_admin_repository.dart';
import 'package:gymrank/features/gym_admin/domain/entities/gym_entity.dart';
import 'package:gymrank/features/gym_admin/domain/repositories/gym_admin_repository.dart';

final gymAdminRepositoryProvider = Provider<GymAdminRepository>((ref) {
  return FirestoreGymAdminRepository(ref.watch(firestoreProvider));
});

final gymDashboardStatsProvider = StreamProvider<GymDashboardStats?>((ref) {
  final gymId = ref.watch(currentUserProvider).valueOrNull?.gymId;
  if (gymId == null) return Stream.value(null);
  return ref.watch(gymAdminRepositoryProvider).watchDashboardStats(gymId);
});
