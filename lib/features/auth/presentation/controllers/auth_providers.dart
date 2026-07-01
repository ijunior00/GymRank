import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:gymrank/features/auth/domain/repositories/auth_repository.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';
import 'package:gymrank/features/profile/presentation/controllers/user_repository_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(userRepositoryProvider),
  );
});

/// uid do usuário autenticado, ou `null` se deslogado. Usado pelo
/// GoRouter para decidir entre fluxo de auth e fluxo autenticado.
final authStateProvider = StreamProvider<String?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Perfil completo (`users/{uid}`) do usuário autenticado, em tempo real.
final currentUserProvider = StreamProvider<UserEntity?>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull;
  if (uid == null) return Stream.value(null);
  final repo = ref.watch(userRepositoryProvider);
  return repo.watch(uid).map((result) => result.dataOrNull);
});
