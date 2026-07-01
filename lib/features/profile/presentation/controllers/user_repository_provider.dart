import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/profile/data/repositories/firestore_user_repository.dart';
import 'package:gymrank/features/profile/domain/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirestoreUserRepository(ref.watch(firestoreProvider));
});
