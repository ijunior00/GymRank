import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/profile/data/repositories/firestore_user_repository.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';
import 'package:gymrank/features/profile/domain/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirestoreUserRepository(ref.watch(firestoreProvider));
});

/// Perfil público de qualquer usuário por id (nome, foto, nível). Usado
/// onde só temos o id — lista de amigos, comentários, embaixadores.
final userByIdProvider =
    StreamProvider.family<UserEntity?, String>((ref, userId) {
  return ref
      .watch(userRepositoryProvider)
      .watch(userId)
      .map((result) => result.dataOrNull);
});
