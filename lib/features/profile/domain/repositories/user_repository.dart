import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/profile/domain/entities/public_profile.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';

abstract interface class UserRepository {
  /// Perfil completo. Só funciona para a própria pessoa e, para o staff,
  /// para as alunas da comunidade — para qualquer outra pessoa use
  /// [watchPublicProfile] / [findPublicProfileByUsername].
  Future<Result<UserEntity>> getById(String uid);

  Future<Result<UserEntity>> create(UserEntity user);

  Future<Result<UserEntity>> update(UserEntity user);

  Future<Result<bool>> isUsernameAvailable(String username);

  Stream<Result<UserEntity>> watch(String uid);

  /// Cartão público de qualquer pessoa (nome, @, foto, nível); `null` se
  /// não existir.
  Stream<PublicProfile?> watchPublicProfile(String uid);

  /// Quem usa este @ (sem o arroba, qualquer caixa); `null` se ninguém.
  Future<Result<PublicProfile?>> findPublicProfileByUsername(String username);
}
