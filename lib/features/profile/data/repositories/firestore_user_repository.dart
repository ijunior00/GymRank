import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/profile/data/dtos/user_dto.dart';
import 'package:gymrank/features/profile/domain/entities/public_profile.dart';
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

  CollectionReference<Map<String, dynamic>> get _publicProfiles =>
      _firestore.collection('public_profiles');

  /// Consulta o espelho público, não `users`: a regra só deixa listar
  /// `users` para a própria pessoa e para o staff, e a busca por @ é de
  /// todo mundo. O espelho é escrito pela function `onUserWritten`
  /// segundos depois do cadastro — bom o bastante para "esse @ já existe?".
  @override
  Future<Result<bool>> isUsernameAvailable(String username) async {
    final found = await findPublicProfileByUsername(username);
    final failure = found.failureOrNull;
    if (failure != null) return Result.failure(failure);
    return Result.success(found.dataOrNull == null);
  }

  @override
  Future<Result<PublicProfile?>> findPublicProfileByUsername(
    String username,
  ) async {
    try {
      final normalized = username.replaceFirst('@', '').trim().toLowerCase();
      if (normalized.isEmpty) return const Result.success(null);
      final query = await _publicProfiles
          .where('usernameLowercase', isEqualTo: normalized)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return const Result.success(null);
      return Result.success(_publicProfileFromSnapshot(query.docs.first));
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Stream<PublicProfile?> watchPublicProfile(String uid) {
    return _publicProfiles.doc(uid).snapshots().map(
          (doc) => doc.exists ? _publicProfileFromSnapshot(doc) : null,
        );
  }

  PublicProfile _publicProfileFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const {};
    return PublicProfile(
      id: doc.id,
      name: d['name'] as String? ?? '',
      username: d['username'] as String? ?? '',
      photoUrl: d['photoUrl'] as String?,
      level: (d['level'] as num?)?.toInt() ?? 1,
    );
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
