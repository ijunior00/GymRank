import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Erro de domínio, desacoplado de exceptions de infraestrutura
/// (FirebaseException, SocketException, etc). Repositórios traduzem
/// exceptions concretas para [Failure] antes de retornar ao domínio.
@freezed
class Failure with _$Failure {
  const factory Failure.network() = NetworkFailure;
  const factory Failure.unauthenticated() = UnauthenticatedFailure;
  const factory Failure.permissionDenied() = PermissionDeniedFailure;
  const factory Failure.notFound() = NotFoundFailure;
  const factory Failure.validation(String message) = ValidationFailure;
  const factory Failure.conflict(String message) = ConflictFailure;
  const factory Failure.unexpected(String message) = UnexpectedFailure;
}
