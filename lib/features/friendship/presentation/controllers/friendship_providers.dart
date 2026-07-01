import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/friendship/data/repositories/firestore_friendship_repository.dart';
import 'package:gymrank/features/friendship/domain/entities/friendship_entity.dart';
import 'package:gymrank/features/friendship/domain/repositories/friendship_repository.dart';

final friendshipRepositoryProvider = Provider<FriendshipRepository>((ref) {
  return FirestoreFriendshipRepository(ref.watch(firestoreProvider));
});

final myFriendshipsProvider = StreamProvider<List<FriendshipEntity>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull;
  if (uid == null) return Stream.value(const []);
  return ref.watch(friendshipRepositoryProvider).watchFriendships(uid);
});
