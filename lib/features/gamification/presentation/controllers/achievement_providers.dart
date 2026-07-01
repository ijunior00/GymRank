import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/gamification/data/repositories/firestore_achievement_repository.dart';
import 'package:gymrank/features/gamification/domain/entities/achievement_entity.dart';
import 'package:gymrank/features/gamification/domain/repositories/achievement_repository.dart';

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return FirestoreAchievementRepository(ref.watch(firestoreProvider));
});

final unlockedAchievementsProvider =
    StreamProvider<List<UserAchievementEntity>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull;
  if (uid == null) return Stream.value(const []);
  return ref.watch(achievementRepositoryProvider).watchUnlocked(uid);
});
