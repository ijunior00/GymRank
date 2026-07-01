import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/auth/domain/repositories/auth_repository.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';
import 'package:gymrank/features/profile/domain/repositories/user_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._userRepository);

  final fb.FirebaseAuth _auth;
  final UserRepository _userRepository;

  @override
  Stream<String?> authStateChanges() {
    return _auth.authStateChanges().map((user) => user?.uid);
  }

  @override
  Future<Result<UserEntity>> currentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Result.failure(Failure.unauthenticated());
    return _userRepository.getById(uid);
  }

  @override
  Future<Result<String>> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return const Result.failure(Failure.validation('Login cancelado'));
      }
      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      return Result.success(result.user!.uid);
    } on fb.FirebaseAuthException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<String>> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oAuthCredential = fb.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final result = await _auth.signInWithCredential(oAuthCredential);
      return Result.success(result.user!.uid);
    } on fb.FirebaseAuthException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<String>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Result.success(result.user!.uid);
    } on fb.FirebaseAuthException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<String>> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Result.success(result.user!.uid);
    } on fb.FirebaseAuthException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  String? _pendingVerificationId;

  @override
  Future<Result<void>> sendPhoneVerificationCode(String phoneNumber) async {
    final completer = Completer<Result<void>>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (_) {},
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.complete(Result.failure(_mapException(e)));
        }
      },
      codeSent: (verificationId, _) {
        _pendingVerificationId = verificationId;
        if (!completer.isCompleted) {
          completer.complete(const Result.success(null));
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    return completer.future;
  }

  @override
  Future<Result<String>> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final id = verificationId.isNotEmpty
          ? verificationId
          : _pendingVerificationId;
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: id!,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      return Result.success(result.user!.uid);
    } on fb.FirebaseAuthException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> isUsernameAvailable(String username) {
    return _userRepository.isUsernameAvailable(username);
  }

  @override
  Future<Result<UserEntity>> completeSignUp({
    required String uid,
    required SignUpData data,
  }) {
    final user = UserEntity(
      id: uid,
      name: data.name,
      username: data.username,
      photoUrl: null,
      birthDate: data.birthDate,
      sex: data.sex,
      heightCm: data.heightCm,
      city: data.city,
      gymId: data.gymId,
      goal: data.goal,
      role: UserRole.aluno,
      level: 1,
      xpTotal: 0,
      xpCurrentSeason: 0,
      gymScore: 0,
      currentStreakDays: 0,
      longestStreakDays: 0,
      lastCheckInAt: null,
      plan: SubscriptionPlan.free,
      createdAt: DateTime.now(),
    );
    return _userRepository.create(user);
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Usuário pode não ter autenticado via Google; ignora e prossegue.
    }
    await _auth.signOut();
  }

  Failure _mapException(fb.FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' || 'wrong-password' || 'invalid-credential' =>
        const Failure.validation('Credenciais inválidas'),
      'email-already-in-use' => const Failure.conflict('E-mail já cadastrado'),
      'network-request-failed' => const Failure.network(),
      _ => Failure.unexpected(e.message ?? e.code),
    };
  }
}
