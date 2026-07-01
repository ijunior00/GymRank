import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/auth/domain/repositories/auth_repository.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  Future<Failure?> signInWithGoogle() => _run(
    () => ref.read(authRepositoryProvider).signInWithGoogle(),
  );

  Future<Failure?> signInWithApple() => _run(
    () => ref.read(authRepositoryProvider).signInWithApple(),
  );

  Future<Failure?> signInWithEmail(String email, String password) => _run(
    () => ref
        .read(authRepositoryProvider)
        .signInWithEmail(email: email, password: password),
  );

  Future<Failure?> registerWithEmail(String email, String password) => _run(
    () => ref
        .read(authRepositoryProvider)
        .registerWithEmail(email: email, password: password),
  );

  Future<Failure?> completeSignUp(String uid, SignUpData data) => _run(
    () => ref.read(authRepositoryProvider).completeSignUp(uid: uid, data: data),
  );

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();

  Future<Failure?> _run<T>(Future<Result<T>> Function() action) async {
    state = const AsyncLoading();
    final result = await action();
    final failure = result.failureOrNull;
    state = failure == null
        ? const AsyncData(null)
        : AsyncError(failure, StackTrace.current);
    return failure;
  }
}
