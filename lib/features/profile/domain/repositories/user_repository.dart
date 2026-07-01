import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';

abstract interface class UserRepository {
  Future<Result<UserEntity>> getById(String uid);

  Future<Result<UserEntity>> create(UserEntity user);

  Future<Result<UserEntity>> update(UserEntity user);

  Future<Result<bool>> isUsernameAvailable(String username);

  Stream<Result<UserEntity>> watch(String uid);
}
