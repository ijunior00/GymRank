import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/profile/data/repositories/firestore_user_repository.dart';
import 'package:gymrank/features/profile/domain/entities/public_profile.dart';
import 'package:gymrank/features/profile/domain/repositories/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirestoreUserRepository(ref.watch(firestoreProvider));
});

/// Cartão público de qualquer pessoa por id (nome, @, foto, nível). Usado
/// onde só temos o id — lista de amigas, comentários, embaixadoras. Lê
/// `public_profiles`, não `users`: o perfil completo de outra pessoa a
/// regra não entrega (e não deve).
final userByIdProvider =
    StreamProvider.family<PublicProfile?, String>((ref, userId) {
  return ref.watch(userRepositoryProvider).watchPublicProfile(userId);
});
