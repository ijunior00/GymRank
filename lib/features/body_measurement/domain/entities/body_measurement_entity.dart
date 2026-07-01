import 'package:freezed_annotation/freezed_annotation.dart';

part 'body_measurement_entity.freezed.dart';

/// Um registro imutável de `body_measurements/{measurementId}`. O
/// histórico nunca é apagado ou editado — apenas novos registros são
/// adicionados (ver regra de negócio em docs/firestore-schema.md).
@freezed
class BodyMeasurementEntity with _$BodyMeasurementEntity {
  const factory BodyMeasurementEntity({
    required String id,
    required String userId,
    required DateTime recordedAt,
    double? pesoKg,
    double? percentualGordura,
    double? massaMuscularKg,
    double? imc,
    double? bracoCm,
    double? peitoralCm,
    double? cinturaCm,
    double? abdomenCm,
    double? quadrilCm,
    double? coxaCm,
    double? panturrilhaCm,
  }) = _BodyMeasurementEntity;
}
