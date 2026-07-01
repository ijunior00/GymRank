import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/profile/data/dtos/user_dto.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';
import 'package:gymrank/features/profile/domain/repositories/user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<Result<UserEntity>> getById(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists) return const Result.failure(Failure.notFound());
      return Result.success(UserDto.fromSnapshot(doc));
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Stream<Result<UserEntity>> watch(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return const Result.failure(Failure.notFound());
      return Result.success(UserDto.fromSnapshot(doc));
    });
  }

  @override
  Future<Result<UserEntity>> create(UserEntity user) async {
    try {
      await _users.doc(user.id).set(UserDto(user).toMap());
      return Result.success(user);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<UserEntity>> update(UserEntity user) async {
    try {
      await _users.doc(user.id).update(UserDto(user).toMap());
      return Result.success(user);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<bool>> isUsernameAvailable(String username) async {
    try {
      final query = await _users
          .where('usernameLowercase', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      return Result.success(query.docs.isEmpty);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  Failure _mapException(FirebaseException e) {
    return switch (e.code) {
      'permission-denied' => const Failure.permissionDenied(),
      'not-found' => const Failure.notFound(),
      'unavailable' => const Failure.network(),
      _ => Failure.unexpected(e.message ?? e.code),
    };
  }
}
