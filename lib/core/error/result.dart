import 'package:freezed_annotation/freezed_annotation.dart';
import 'failure.dart';

part 'result.freezed.dart';

/// Either simplificado: toda operação de use case/repositório retorna
/// [Result] em vez de lançar exceptions, forçando tratamento explícito
/// de erro na camada de apresentação.
@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(Failure failure) = ResultFailure<T>;
}

extension ResultX<T> on Result<T> {
  bool get isSuccess => this is Success<T>;

  T? get dataOrNull => switch (this) {
    Success<T>(:final data) => data,
    ResultFailure<T>() => null,
  };

  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    ResultFailure<T>(:final failure) => failure,
  };
}
