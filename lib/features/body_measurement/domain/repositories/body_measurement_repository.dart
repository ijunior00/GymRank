import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/body_measurement/domain/entities/body_measurement_entity.dart';

abstract interface class BodyMeasurementRepository {
  /// Histórico completo em ordem cronológica. Nunca há update/delete —
  /// apenas `add`.
  Stream<List<BodyMeasurementEntity>> watchHistory(String userId);

  Future<Result<BodyMeasurementEntity>> add(BodyMeasurementEntity entry);
}
