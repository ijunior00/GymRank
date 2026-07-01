import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/rewards/data/repositories/firestore_reward_repository.dart';
import 'package:gymrank/features/rewards/domain/entities/reward_entity.dart';
import 'package:gymrank/features/rewards/domain/repositories/reward_repository.dart';

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  return FirestoreRewardRepository(ref.watch(firestoreProvider));
});

final myRewardGrantsProvider = StreamProvider<List<RewardGrantEntity>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull;
  if (uid == null) return Stream.value(const []);
  return ref.watch(rewardRepositoryProvider).watchMyGrants(uid);
});
